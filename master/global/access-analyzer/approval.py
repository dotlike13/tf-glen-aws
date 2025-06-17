import json
import boto3
import os
import requests
from botocore.exceptions import ClientError
from urllib.parse import parse_qs, unquote_plus
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import datetime

# 기본값 설정
DEFAULT_ANALYZER_ARN = os.environ.get('ANALYZER_ARN')
SLACK_BOT_TOKEN = os.environ.get('SLACK_BOT_TOKEN')

def get_policy_from_file(slack_client, file_id):
    """Slack에 업로드된 파일에서 정책 내용을 가져옵니다."""
    try:
        # 파일 정보 조회
        file_info = slack_client.files_info(file=file_id)
        
        # 파일 내용 다운로드
        response = requests.get(file_info['file']['url_private'], 
                              headers={'Authorization': f'Bearer {SLACK_BOT_TOKEN}'})
        response.raise_for_status()
        
        # JSON 파싱
        return json.loads(response.text)
    except Exception as e:
        print(f"파일에서 정책 조회 중 오류 발생: {str(e)}")
        raise e

def send_slack_response(response_url, message, thread_ts=None):
    """Slack에 응답 메시지를 전송합니다."""
    payload = {
        "text": message,
        "response_type": "in_channel"
    }
    if thread_ts:
        payload["thread_ts"] = thread_ts
    
    try:
        response = requests.post(response_url, json=payload)
        response.raise_for_status()
        print(f"Slack 응답 전송 성공: {message}")
    except Exception as e:
        print(f"Slack 응답 전송 실패: {str(e)}")

def create_and_attach_policy(iam_client, role_name, policy_document, finding_id):
    """새로운 정책을 생성하고 연결합니다."""
    try:
        # 새로운 정책 이름 생성
        policy_name = f'recommended-policy-{finding_id}'
        
        # 새로운 관리형 정책 생성
        policy_response = iam_client.create_policy(
            PolicyName=policy_name,
            PolicyDocument=json.dumps(policy_document),
            Description=f'Recommended policy created from Access Analyzer finding {finding_id}'
        )
        policy_arn = policy_response['Policy']['Arn']
        
        # 기존 정책들 제거
        print(f"기존 정책 제거 시작 - 역할: {role_name}")
        
        # 연결된 관리형 정책 제거
        attached_policies = iam_client.list_attached_role_policies(RoleName=role_name)
        for policy in attached_policies['AttachedPolicies']:
            print(f"관리형 정책 제거: {policy['PolicyArn']}")
            iam_client.detach_role_policy(
                RoleName=role_name,
                PolicyArn=policy['PolicyArn']
            )
        
        # 인라인 정책 제거
        inline_policies = iam_client.list_role_policies(RoleName=role_name)
        for policy_name in inline_policies['PolicyNames']:
            print(f"인라인 정책 제거: {policy_name}")
            iam_client.delete_role_policy(
                RoleName=role_name,
                PolicyName=policy_name
            )
        
        # 새로운 정책 연결
        print(f"새로운 정책 연결: {policy_arn}")
        iam_client.attach_role_policy(
            RoleName=role_name,
            PolicyArn=policy_arn
        )
        
        return policy_name
    except Exception as e:
        print(f"정책 생성 및 연결 중 오류 발생: {str(e)}")
        raise e

def lambda_handler(event, context):
    try:
        # 디버깅을 위한 입력 데이터 로깅
        print("받은 이벤트:", event)
        print("이벤트 타입:", type(event))
        
        # URL 인코딩된 body를 디코딩
        body = event.get('body', '')
        print("Raw body:", body)
        
        # form 데이터 파싱
        parsed_body = parse_qs(body)
        print("Parsed body:", parsed_body)
        
        # payload 추출 및 JSON 파싱
        payload = parsed_body.get('payload', ['{}'])[0]
        payload = json.loads(payload)
        print("Payload:", payload)
        
        # 응답 URL과 쓰레드 정보 추출
        response_url = payload.get('response_url')
        thread_ts = payload.get('container', {}).get('thread_ts') or payload.get('message', {}).get('thread_ts')
        
        # 액션 값 파싱 (value 필드는 이스케이프된 JSON 문자열)
        action_value = payload['actions'][0]['value']
        action_value = json.loads(action_value)
        print("Action value:", action_value)
        
        action = action_value['action']  # approve 또는 deny
        finding_id = action_value['finding_id']
        analyzer_arn = action_value.get('analyzer_arn', DEFAULT_ANALYZER_ARN)
        
        # Access Analyzer 클라이언트 생성
        analyzer_client = boto3.client('accessanalyzer', region_name=os.environ.get('AWS_REGION', 'ap-northeast-2'))
        
        if action == 'approve':
            # 승인 처리
            try:
                if action_value['type'] == 'permission':
                    # IAM 클라이언트 생성
                    iam_client = boto3.client('iam')
                    
                    # Slack 클라이언트 생성
                    slack_client = WebClient(token=SLACK_BOT_TOKEN)
                    
                    # 파일에서 정책 내용 가져오기
                    policy = get_policy_from_file(slack_client, action_value['file_id'])
                    resource_type = action_value['resource_type']
                    resource = action_value['resource']
                    
                    # 새로운 정책 이름 생성 (타임스탬프 추가)
                    timestamp = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
                    policy_name = f'recommended-policy-{timestamp}'
                    
                    # 새로운 정책 생성
                    policy_response = iam_client.create_policy(
                        PolicyName=policy_name,
                        PolicyDocument=json.dumps(policy),
                        Description=f'Recommended policy created from Access Analyzer finding {finding_id}'
                    )
                    policy_arn = policy_response['Policy']['Arn']
                    
                    if resource_type == 'AWS::IAM::Role':
                        role_name = resource.split('/')[-1]
                        
                        # 기존 정책들 제거
                        print(f"기존 정책 제거 시작 - 역할: {role_name}")
                        
                        # 연결된 관리형 정책 제거
                        attached_policies = iam_client.list_attached_role_policies(RoleName=role_name)
                        for policy in attached_policies['AttachedPolicies']:
                            print(f"관리형 정책 제거: {policy['PolicyArn']}")
                            iam_client.detach_role_policy(
                                RoleName=role_name,
                                PolicyArn=policy['PolicyArn']
                            )
                        
                        # 인라인 정책 제거
                        inline_policies = iam_client.list_role_policies(RoleName=role_name)
                        for policy_name in inline_policies['PolicyNames']:
                            print(f"인라인 정책 제거: {policy_name}")
                            iam_client.delete_role_policy(
                                RoleName=role_name,
                                PolicyName=policy_name
                            )
                        
                        # 새로운 정책 연결
                        print(f"새로운 정책 연결: {policy_arn}")
                        iam_client.attach_role_policy(
                            RoleName=role_name,
                            PolicyArn=policy_arn
                        )
                        
                        success_message = f"✅ 역할 '{role_name}'에 새로운 추천 정책 '{policy_name}'이 생성되고 연결되었습니다. 결과는 아카이브 처리되었습니다."
                        
                    elif resource_type == 'AWS::IAM::User':
                        user_name = resource.split('/')[-1]
                        
                        # 기존 정책들 제거
                        print(f"기존 정책 제거 시작 - 사용자: {user_name}")
                        
                        # 연결된 관리형 정책 제거
                        attached_policies = iam_client.list_attached_user_policies(UserName=user_name)
                        for policy in attached_policies['AttachedPolicies']:
                            print(f"관리형 정책 제거: {policy['PolicyArn']}")
                            iam_client.detach_user_policy(
                                UserName=user_name,
                                PolicyArn=policy['PolicyArn']
                            )
                        
                        # 인라인 정책 제거
                        inline_policies = iam_client.list_user_policies(UserName=user_name)
                        for policy_name in inline_policies['PolicyNames']:
                            print(f"인라인 정책 제거: {policy_name}")
                            iam_client.delete_user_policy(
                                UserName=user_name,
                                PolicyName=policy_name
                            )
                        
                        # 새로운 정책 연결
                        print(f"새로운 정책 연결: {policy_arn}")
                        iam_client.attach_user_policy(
                            UserName=user_name,
                            PolicyArn=policy_arn
                        )
                        
                        success_message = f"✅ 사용자 '{user_name}'에 새로운 추천 정책 '{policy_name}'이 생성되고 연결되었습니다. 결과는 아카이브 처리되었습니다."
                        
                    else:
                        error_message = f"❌ 지원하지 않는 리소스 타입입니다: {resource_type}"
                        send_slack_response(response_url, error_message, thread_ts)
                        return {
                            'statusCode': 400,
                            'body': json.dumps({'error': error_message})
                        }
                    
                    # Finding 아카이브 처리
                    analyzer_client.update_findings(
                        analyzerArn=analyzer_arn,
                        ids=[finding_id],
                        status='ARCHIVED'
                    )
                    
                    print(success_message)
                    # Slack에 결과 전송
                    send_slack_response(response_url, success_message, thread_ts)
                    
                    return {
                        'statusCode': 200,
                        'body': json.dumps({
                            'message': success_message,
                            'finding_id': finding_id
                        })
                    }
                    
                elif action_value['type'] == 'role':
                    # 역할 삭제 처리
                    iam_client = boto3.client('iam')
                    role_name = action_value['role_name']
                    
                    # 역할에 태그 추가
                    iam_client.tag_role(
                        RoleName=role_name,
                        Tags=[
                            {
                                'Key': 'key',
                                'Value': 'security'
                            }
                        ]
                    )
                    
                    # 역할에 연결된 정책들 제거
                    attached_policies = iam_client.list_attached_role_policies(RoleName=role_name)['AttachedPolicies']
                    for policy in attached_policies:
                        iam_client.detach_role_policy(RoleName=role_name, PolicyArn=policy['PolicyArn'])
                    
                    # 인라인 정책들 제거
                    inline_policies = iam_client.list_role_policies(RoleName=role_name)['PolicyNames']
                    for policy_name in inline_policies:
                        iam_client.delete_role_policy(RoleName=role_name, PolicyName=policy_name)
                    
                    # 역할 삭제
                    iam_client.delete_role(RoleName=role_name)
                    
                    # Finding 아카이브
                    analyzer_client.update_findings(
                        analyzerArn=analyzer_arn,
                        ids=[finding_id],
                        status='ARCHIVED'
                    )
                    
                    success_message = f"✅ 미사용 역할 '{role_name}'이(가) 삭제 및 아카이브 처리되었습니다."
                    # Slack에 결과 전송
                    send_slack_response(response_url, success_message, thread_ts)
                    
                    return {
                        'statusCode': 200,
                        'body': json.dumps({
                            'message': success_message,
                            'finding_id': finding_id
                        })
                    }
                    
            except Exception as e:
                error_message = f"❌ 처리 중 오류가 발생했습니다: {str(e)}"
                print(error_message)
                # Slack에 오류 메시지 전송
                send_slack_response(response_url, error_message, thread_ts)
                return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'message': error_message,
                        'finding_id': finding_id
                    })
                }
                
        elif action == 'deny':
            try:
                # IAM 클라이언트 생성
                iam_client = boto3.client('iam')
                resource = action_value['resource']
                resource_type = action_value.get('resource_type')
                
                if resource_type == 'AWS::IAM::Role':
                    role_name = resource.split('/')[-1]
                    
                    # 역할에 태그 추가
                    iam_client.tag_role(
                        RoleName=role_name,
                        Tags=[
                            {
                                'Key': 'key',
                                'Value': 'security'
                            }
                        ]
                    )
                    
                    success_message = f"✅ 역할 '{role_name}'에 'security' 태그 추가 및 아카이브 처리되었습니다."
                elif resource_type == 'AWS::IAM::User':
                    user_name = resource.split('/')[-1]
                    
                    # 사용자에 태그 추가
                    iam_client.tag_user(
                        UserName=user_name,
                        Tags=[
                            {
                                'Key': 'key',
                                'Value': 'security'
                            }
                        ]
                    )
                    
                    success_message = f"✅ 사용자 '{user_name}'에 'security' 태그 추가 및 아카이브 처리되었습니다."
                else:
                    success_message = f"✅ 리소스 '{resource}'의 Finding이 아카이브 처리되었습니다. 콘솔에서 확인해주세요."
                
                # 모든 경우에 Finding 아카이브 처리
                analyzer_client.update_findings(
                    analyzerArn=analyzer_arn,
                    ids=[finding_id],
                    status='ARCHIVED'
                )
                
                # Slack에 결과 전송
                send_slack_response(response_url, success_message, thread_ts)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': success_message,
                        'finding_id': finding_id
                    })
                }
            except Exception as e:
                error_message = f"❌ 처리 중 오류가 발생했습니다: {str(e)}"
                print(error_message)
                # Slack에 오류 메시지 전송
                send_slack_response(response_url, error_message, thread_ts)
                return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'message': error_message,
                        'finding_id': finding_id
                    })
                }
            
        else:
            error_message = "❌ 잘못된 액션입니다."
            # Slack에 오류 메시지 전송
            send_slack_response(response_url, error_message, thread_ts)
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': error_message,
                    'finding_id': finding_id
                })
            }
            
    except Exception as e:
        error_message = f"❌ 처리 중 오류가 발생했습니다: {str(e)}"
        print(error_message)
        # response_url이 있는 경우에만 Slack에 오류 메시지 전송
        if 'response_url' in locals():
            send_slack_response(response_url, error_message, thread_ts)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': error_message
            })
        }
