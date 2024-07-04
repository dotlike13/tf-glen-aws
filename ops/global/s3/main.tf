module "s3" {
  source = "./module"

  name = "s3-website-test.mydomain.com"
  
  sse_key_id = "arn:aws:kms:us-east-1:${var.account}:key/mrk-812ea9c2f1fe4397af6c672e14a4d1f7"

  cors_rules = [
    {
        allowed_headers = ["*"]
        allowed_methods = ["OPTIONS", "GET", "PUT", "POST"]
        allowed_origins = ["https://s3-website-test.mydomain.com"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3000
    }
  ]

}