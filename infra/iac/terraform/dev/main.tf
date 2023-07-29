#################################
## POSTGRESQL (DEV && GEONODE) ##
#################################
resource "hcloud_ssh_key" "ssh_key" {
  name       = "postgresql-dev-geonode"
  public_key = file(var.ssh_key_file)
}

resource "aws_iam_user" "backup_user" {
  name = "srv_dev_${data.aws_s3_bucket.backup.id}"
}

resource "aws_iam_access_key" "user_keys" {
  user = aws_iam_user.backup_user.name
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  bucket = data.aws_s3_bucket.backup.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.backup_user.arn}"
      },
      "Action": [ "s3:*" ],
      "Resource": [
        "${data.aws_s3_bucket.backup.arn}",
        "${data.aws_s3_bucket.backup.arn}/*"
      ]
    }
  ]
}
EOF
}


resource "random_password" "db_admin_password" {
  length  = 16
  special = false
  numeric = true
  upper   = true
  lower   = true
}

resource "aws_secretsmanager_secret" "db_admin_password" {
  name        = "dev_geonode_db_admin_password"
  description = "Password for the database admin user"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_admin_password" {
  secret_id     = aws_secretsmanager_secret.db_admin_password.id
  secret_string = random_password.db_admin_password.result
}

data "aws_secretsmanager_secret_version" "db_admin_password" {
  secret_id = aws_secretsmanager_secret.db_admin_password.id

  depends_on = [
    aws_secretsmanager_secret_version.db_admin_password
  ]
}


module "postgresql" {
  source        = "../modules/postgres"
  instance_name = "geonode-dev-db"

  ssh_keys    = [hcloud_ssh_key.ssh_key.id]
  data_volume = data.hcloud_volume.data.id

  backup_s3_bucket     = data.aws_s3_bucket.backup.id
  backup_s3_access_key = aws_iam_access_key.user_keys.id
  backup_s3_secret_key = aws_iam_access_key.user_keys.secret


  db_admin_password = data.aws_secretsmanager_secret_version.db_admin_password.secret_string
  databases         = []
}

