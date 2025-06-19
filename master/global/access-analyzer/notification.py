import boto3
import requests
import json
import uuid
import time
import os
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# 환경 변수에서 설정값 가져오기
REGION = os.environ.get('AWS_REGION', 'ap-northeast-2')
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL')
SLACK_BOT_TOKEN = os.environ.get('SLACK_BOT_TOKEN')
SLACK_CHANNEL = os.environ.get('SLACK_CHANNEL')
ANALYZER_ARN = os.environ.get('ANALYZER_ARN')

# AWS 클라이언트
accessanalyzer = boto3.client('accessanalyzer', region_name=REGION)
iam = boto3.client('iam', region_name=REGION)

# Slack 클라이언트 초기화
slack_client = WebClient(token=SLACK_BOT_TOKEN)

def get_unused_access_findings(analyzer_arn):
    findings = []
    paginator = accessanalyzer.get_paginator('list_findings_v2')
    filter = {
        'findingType': {
            'eq': ['UnusedPermission', 'UnusedIAMRole']
        },
        'status': {
            'eq': ['ACTIVE']
        }
    }
    
    print(f"\n=== Finding 조회 시작 ===")
    page_count = 0
    for page in paginator.paginate(analyzerArn=analyzer_arn, filter=filter, PaginationConfig={'PageSize': 100}):
        page_findings = page.get('findings', [])
        page_count += 1
        print(f"페이지 {page_count}: {len(page_findings)}개의 finding 발견")
        for finding in page_findings:
            print(f"- Finding ID: {finding.get('id')}, Resource: {finding.get('resource')}, Type: {finding.get('findingType')}")
        findings.extend(page_findings)
    
    print(f"\n총 {len(findings)}개의 finding 조회됨")
    print("=== Finding 조회 완료 ===\n")
    return findings

def get_finding_recommendation(finding):
    try:
        print(f"\n=== Finding 추천 정책 조회 시작 - {finding.get('resource')} ===")
        if finding['findingType'] != 'UnusedPermission':
            print(f"Finding 타입이 UnusedPermission이 아님: {finding['findingType']}")
            return None

        resource_type = finding.get('resourceType')
        resource_arn = finding.get('resource')
        print(f"리소스 타입: {resource_type}")
        print(f"리소스 ARN: {resource_arn}")

        # SSO 역할인 경우 바로 CloudTrail 검토 필요 반환
        if 'aws-reserved/sso.amazonaws.com' in resource_arn:
            print("SSO 역할은 추천 정책 생성이 지원되지 않습니다.")
            return "CloudTrail 검토 필요"

        try:
            analyzer_arn = finding.get('analyzerArn', 'arn:aws:access-analyzer:ap-northeast-2:339713010523:analyzer/unused-access-analyzer-prod')
            finding_id = finding['id']
            
            print(f"Finding ID: {finding_id}")
            print(f"Analyzer ARN: {analyzer_arn}")
            
            # 먼저 추천 정책 생성 요청
            print("추천 정책 생성 요청 중...")
            try:
                # 모든 preview 목록 조회
                preview_response = accessanalyzer.list_access_previews(
                    analyzerArn=analyzer_arn,
                    maxResults=10
                )
                previews = preview_response.get('accessPreviews', [])
                print(f"발견된 preview 수: {len(previews)}")

                if not previews:
                    # preview가 없는 경우 새로 생성
                    generate_response = accessanalyzer.generate_finding_recommendation(
                        analyzerArn=analyzer_arn,
                        id=finding_id
                    )
                    print("새로운 추천 정책 생성됨")
                else:
                    print("기존 preview 사용")

            except accessanalyzer.exceptions.ValidationException as e:
                print(f"추천 정책 생성 실패 (ValidationException): {str(e)}")
                return "CloudTrail 검토 필요"
            except Exception as e:
                print(f"추천 정책 생성 실패: {str(e)}")
                return "CloudTrail 검토 필요"
            
            # 추천 정책이 생성될 때까지 대기
            print("추천 정책 생성 대기 중...")
            max_attempts = 12  # 최대 1분(5초 * 12) 동안 시도
            attempt = 0
            
            while attempt < max_attempts:
                try:
                    response = accessanalyzer.get_finding_recommendation(
                        analyzerArn=analyzer_arn,
                        id=finding_id
                    )
                    
                    status = response.get('status')
                    print(f"추천 정책 조회 상태: {status} (시도 {attempt + 1}/{max_attempts})")
                    
                    if status == 'SUCCEEDED':
                        break
                    
                    attempt += 1
                    if attempt < max_attempts:
                        time.sleep(5)
                    
                except accessanalyzer.exceptions.ResourceNotFoundException:
                    print("추천 정책을 찾을 수 없습니다.")
                    return "CloudTrail 검토 필요"
                except Exception as e:
                    print(f"추천 정책 조회 실패: {str(e)}")
                    return "CloudTrail 검토 필요"
            
            if status != 'SUCCEEDED':
                print(f"추천 정책 생성 시간 초과 (최종 상태: {status})")
                return "CloudTrail 검토 필요"
            
            recommended_steps = response.get('recommendedSteps', [])
            if recommended_steps:
                all_recommendations = []
                for step in recommended_steps:
                    if 'unusedPermissionsRecommendedStep' in step:
                        unused_step = step['unusedPermissionsRecommendedStep']
                        all_recommendations.append({
                            'action': unused_step.get('recommendedAction'),
                            'policy': unused_step.get('recommendedPolicy'),
                            'existingPolicyId': unused_step.get('existingPolicyId'),
                            'policyUpdatedAt': unused_step.get('policyUpdatedAt')
                        })
                if all_recommendations:
                    return all_recommendations
            print("추천 단계가 없습니다.")
            return "CloudTrail 검토 필요"

        except Exception as e:
            print(f"추천 정책 조회 중 오류 발생: {str(e)}")
            return "오류 발생. 검토 필요"

    except Exception as e:
        print(f"Error getting finding recommendation: {str(e)}")
        return None
    finally:
        print("=== Finding 추천 정책 조회 완료 ===\n")

def get_role_attached_policies(role_name):
    attached = iam.list_attached_role_policies(RoleName=role_name)
    inline = iam.list_role_policies(RoleName=role_name)
    return {
        'attached': attached.get('AttachedPolicies', []),
        'inline': inline.get('PolicyNames', [])
    }

def get_role_info(role_name):
    try:
        print(f"\n=== 역할 '{role_name}' 정보 조회 시작 ===")
        role_info = iam.get_role(RoleName=role_name)
        created_date = role_info['Role']['CreateDate'].strftime('%Y-%m-%d %H:%M:%S')
        print(f"생성일: {created_date}")
        
        # 마지막 사용 시간 조회
        last_used = role_info['Role'].get('RoleLastUsed', {})
        if last_used and 'LastUsedDate' in last_used:
            last_activity = last_used['LastUsedDate'].strftime('%Y-%m-%d %H:%M:%S')
            print(f"마지막 사용 시간: {last_activity}")
        else:
            last_activity = "활동 기록 없음"
            print("활동 기록이 없습니다.")
        
        print("=== 역할 정보 조회 완료 ===\n")
        return {
            'created_date': created_date,
            'last_activity': last_activity
        }
    except Exception as e:
        print(f"역할 정보 조회 중 오류 발생: {str(e)}")
        return {
            'created_date': "조회 실패",
            'last_activity': "조회 실패"
        }

def get_user_info(user_name):
    try:
        print(f"\n=== 사용자 '{user_name}' 정보 조회 시작 ===")
        user_info = iam.get_user(UserName=user_name)
        created_date = user_info['User']['CreateDate'].strftime('%Y-%m-%d %H:%M:%S')
        print(f"생성일: {created_date}")
        
        # 액세스 키 목록 조회
        access_keys = iam.list_access_keys(UserName=user_name)
        last_activity = "활동 기록 없음"
        
        if access_keys['AccessKeyMetadata']:
            print("액세스 키 사용 기록 조회 중...")
            for key in access_keys['AccessKeyMetadata']:
                key_info = iam.get_access_key_last_used(AccessKeyId=key['AccessKeyId'])
                if 'LastUsedDate' in key_info['AccessKeyLastUsed']:
                    key_last_used = key_info['AccessKeyLastUsed']['LastUsedDate'].strftime('%Y-%m-%d %H:%M:%S')
                    print(f"액세스 키 {key['AccessKeyId']} 마지막 사용: {key_last_used}")
                    if last_activity == "활동 기록 없음" or key_last_used > last_activity:
                        last_activity = key_last_used
            print(f"최종 마지막 사용 시간: {last_activity}")
        else:
            print("액세스 키가 없습니다.")
        
        print("=== 사용자 정보 조회 완료 ===\n")
        return {
            'created_date': created_date,
            'last_activity': last_activity
        }
    except Exception as e:
        print(f"사용자 정보 조회 중 오류 발생: {str(e)}")
        return {
            'created_date': "조회 실패",
            'last_activity': "조회 실패"
        }

def send_unused_permission_to_slack(finding):
    print(f"\n=== Unused Permission Slack 메시지 전송 시작 - {finding.get('resource')} ===")
    resource = finding['resource']
    finding_id = finding['id']
    resource_type = finding['resourceType']
    resource_name = resource.split('/')[-1]
    
    # 리소스 정보 조회
    if resource_type == 'AWS::IAM::Role':
        resource_info = get_role_info(resource_name)
    elif resource_type == 'AWS::IAM::User':
        resource_info = get_user_info(resource_name)
    else:
        resource_info = {
            'created_date': "지원하지 않는 리소스 타입",
            'last_activity': "지원하지 않는 리소스 타입"
        }
    
    # Finding 추천 정책 가져오기
    recommendation = get_finding_recommendation(finding)
    
    try:
        # 메인 메시지 전송
        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*🛡️ 미사용 권한 발견* `{resource}`"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*생성일:* {resource_info['created_date']}\n*마지막 활동:* {resource_info['last_activity']}"
                }
            }
        ]

        # 추천 정책 상태 표시
        if recommendation == "CloudTrail 검토 필요":
            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "⚠️ CloudTrail 검토가 필요합니다."
                }
            })
        elif isinstance(recommendation, list) and recommendation:
            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "✅ 추천 정책이 생성되었습니다. 아래 쓰레드를 확인해주세요."
                }
            })
            # 추천 정책이 있는 경우에만 버튼 블록 추가
            blocks.append({
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {
                            "type": "plain_text",
                            "text": "✅ Approve 수정"
                        },
                        "style": "primary",
                        "value": json.dumps({
                            "action": "approve",
                            "type": "permission",
                            "finding_id": finding_id,
                            "analyzer_arn": ANALYZER_ARN,
                            "resource": resource,
                            "resource_type": resource_type
                        })
                    },
                    {
                        "type": "button",
                        "text": {
                            "type": "plain_text",
                            "text": "❌ Deny"
                        },
                        "style": "danger",
                        "value": json.dumps({
                            "action": "deny",
                            "type": "permission",
                            "finding_id": finding_id,
                            "analyzer_arn": ANALYZER_ARN,
                            "resource": resource,
                            "resource_type": resource_type
                        })
                    }
                ]
            })
        else:
            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "추천 정책을 조회할 수 없습니다."
                }
            })

        # 메인 메시지 전송
        main_message = slack_client.chat_postMessage(
            channel=SLACK_CHANNEL,
            blocks=blocks,
            text=f"미사용 권한 발견: {resource}"  # 폴백 텍스트
        )
        print(f"Slack 메인 메시지 전송 성공 (ts: {main_message['ts']})")
        
        # 추천 정책이 있는 경우 처리
        if isinstance(recommendation, list) and recommendation:
            rec = recommendation[0]  # 첫 번째 추천 정책만 사용
            if rec.get('policy'):
                try:
                    # 정책 문자열을 JSON으로 파싱
                    policy_json = json.loads(rec.get('policy'))
                    # JSON을 보기 좋게 포맷팅 (들여쓰기 2칸)
                    formatted_policy = json.dumps(policy_json, indent=2, ensure_ascii=False)
                    
                    # JSON 파일 업로드
                    file_upload = slack_client.files_upload_v2(
                        channel=SLACK_CHANNEL,
                        thread_ts=main_message['ts'],
                        content=formatted_policy,
                        filename=f'recommended_policy_{finding_id}.json',
                        title='추천 정책',
                        initial_comment="추천 정책 상세 내용입니다."
                    )
                    print("Slack 파일 업로드 성공")

                    # 추가 정보를 쓰레드 메시지로 전송
                    info_text = ["*추천 정책 상세 정보:*"]
                    if rec.get('existingPolicyId'):
                        info_text.append(f"• *기존 정책 ID:* {rec.get('existingPolicyId')}")
                    if rec.get('policyUpdatedAt'):
                        info_text.append(f"• *정책 마지막 업데이트:* {rec.get('policyUpdatedAt')}")
                    
                    if len(info_text) > 1:  # 추가 정보가 있는 경우에만 전송
                        thread_message = slack_client.chat_postMessage(
                            channel=SLACK_CHANNEL,
                            thread_ts=main_message['ts'],
                            text="\n".join(info_text)
                        )
                        print("Slack 쓰레드 메시지 전송 성공")

                    # 버튼 블록 업데이트 - 파일 ID 참조
                    blocks[-1]['elements'][0]['value'] = json.dumps({
                        "action": "approve",
                        "type": "permission",
                        "finding_id": finding_id,
                        "analyzer_arn": ANALYZER_ARN,
                        "resource": resource,
                        "resource_type": resource_type,
                        "file_id": file_upload['files'][0]['id'],  # 파일 ID만 저장
                        "existing_policy_id": rec.get('existingPolicyId'),
                        "policy_updated_at": rec.get('policyUpdatedAt').strftime('%Y-%m-%d %H:%M:%S') if rec.get('policyUpdatedAt') else None
                    })

                    # Deny 버튼도 업데이트
                    blocks[-1]['elements'][1]['value'] = json.dumps({
                        "action": "deny",
                        "type": "permission",
                        "finding_id": finding_id,
                        "analyzer_arn": ANALYZER_ARN,
                        "resource": resource,
                        "resource_type": resource_type
                    })

                    try:
                        # 업데이트된 버튼으로 메시지 수정
                        slack_client.chat_update(
                            channel=SLACK_CHANNEL,
                            ts=main_message['ts'],
                            blocks=blocks,
                            text=f"미사용 권한 발견: {resource}"
                        )
                    except SlackApiError as e:
                        print(f"Slack API 오류: {str(e)}")
                        error_response = e.response.get('error', '')
                        if error_response == 'invalid_blocks':
                            print("블록 형식이 잘못되었습니다.")
                            metadata = e.response.get('response_metadata', {})
                            if metadata and 'messages' in metadata:
                                print(f"오류 상세: {metadata['messages']}")
                        else:
                            print(f"기타 Slack API 오류: {error_response}")

                except json.JSONDecodeError as e:
                    print(f"정책 JSON 파싱 실패: {str(e)}")
                    # JSON 파싱 실패 시 오류 메시지 전송
                    thread_message = slack_client.chat_postMessage(
                        channel=SLACK_CHANNEL,
                        thread_ts=main_message['ts'],
                        text="⚠️ 정책 JSON 파싱에 실패했습니다. 관리자에게 문의해주세요."
                    )

    except SlackApiError as e:
        print(f"Slack API 오류: {str(e)}")
        error_response = e.response.get('error', '')
        if error_response == "missing_scope":
            print("봇에 필요한 권한이 없습니다. 다음 권한이 필요합니다:")
            metadata = e.response.get('response_metadata', {})
            if metadata:
                if 'needed' in metadata:
                    print(f"필요한 권한: {metadata['needed']}")
                if 'provided' in metadata:
                    print(f"현재 권한: {metadata['provided']}")
        elif error_response == "channel_not_found":
            print("채널을 찾을 수 없습니다. 채널 ID를 확인하고 봇을 채널에 초대했는지 확인해주세요.")
        elif error_response == "not_in_channel":
            print("봇이 채널에 초대되어 있지 않습니다. 채널에 봇을 초대해주세요.")
        elif error_response == "invalid_blocks":
            print("블록 형식이 잘못되었습니다:")
            metadata = e.response.get('response_metadata', {})
            if metadata and 'messages' in metadata:
                print(f"오류 상세: {metadata['messages']}")
        else:
            print(f"기타 Slack API 오류: {error_response}")
    
    print("=== Unused Permission Slack 메시지 전송 완료 ===\n")

def send_unused_role_to_slack(finding):
    print(f"\n=== Unused Role Slack 메시지 전송 시작 - {finding.get('resource')} ===")
    resource = finding['resource']
    finding_id = finding['id']
    role_name = resource.split('/')[-1]
    
    # 역할 정보 조회
    role_info = get_role_info(role_name)
    
    # 역할 정책 정보 가져오기
    policies = get_role_attached_policies(role_name)
    
    block = {
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*🛡️ 미사용 역할 발견* `{resource}`"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*생성일:* {role_info['created_date']}\n*마지막 활동:* {role_info['last_activity']}"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*Attached Policies:*\n" + "\n".join([f"• {p['PolicyName']}" for p in policies['attached']]) or "없음"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*Inline Policies:*\n" + "\n".join([f"• {p}" for p in policies['inline']]) or "없음"
                }
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "✅ Approve 삭제"},
                        "style": "primary",
                        "value": json.dumps({
                            "action": "approve",
                            "type": "role",
                            "finding_id": finding_id,
                            "analyzer_arn": ANALYZER_ARN,
                            "resource": resource,
                            "role_name": role_name,
                            "resource_type": finding['resourceType']
                        })
                    },
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "❌ Deny"},
                        "style": "danger",
                        "value": json.dumps({
                            "action": "deny",
                            "type": "role",
                            "finding_id": finding_id,
                            "analyzer_arn": ANALYZER_ARN,
                            "resource": resource,
                            "role_name": role_name,
                            "resource_type": finding['resourceType']
                        })
                    }
                ]
            }
        ]
    }
    response = requests.post(SLACK_WEBHOOK_URL, data=json.dumps(block), headers={'Content-Type': 'application/json'})
    print(f"Slack 응답 상태: {response.status_code}")
    print("=== Unused Role Slack 메시지 전송 완료 ===\n")

def main():
    print("\n=== 프로그램 시작 ===")
    findings = get_unused_access_findings(ANALYZER_ARN)
    print(f"\n총 {len(findings)}개의 finding 처리 시작")

    for idx, finding in enumerate(findings, 1):
        print(f"\n[{idx}/{len(findings)}] Finding 처리 중...")
        finding_type = finding.get('findingType')
        
        if finding_type == 'UnusedPermission':
            print(f"미사용 권한 처리: {finding.get('resource')}")
            send_unused_permission_to_slack(finding)
        elif finding_type == 'UnusedIAMRole':
            print(f"미사용 역할 처리: {finding.get('resource')}")
            send_unused_role_to_slack(finding)
        else:
            print(f"알 수 없는 Finding 타입: {finding_type}")
    
    print("\n=== 프로그램 종료 ===")

def lambda_handler(event, context):
    """
    Lambda 핸들러 함수
    """
    try:
        print("\n=== Lambda 함수 시작 ===")
        
        # 환경 변수 검증
        required_env_vars = ['SLACK_WEBHOOK_URL', 'SLACK_BOT_TOKEN', 'SLACK_CHANNEL', 'ANALYZER_ARN']
        missing_vars = [var for var in required_env_vars if not os.environ.get(var)]
        if missing_vars:
            raise ValueError(f"필수 환경 변수가 설정되지 않았습니다: {', '.join(missing_vars)}")
        
        # 메인 함수 실행
        main()
        
        return {
            'statusCode': 200,
            'body': json.dumps('Success')
        }
        
    except Exception as e:
        print(f"Lambda 함수 실행 중 오류 발생: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
    finally:
        print("=== Lambda 함수 종료 ===\n")

if __name__ == "__main__":
    # 로컬 테스트용
    lambda_handler(None, None)
