resource "aws_dynamodb_table" "mytable" {
  name                        = "MyTable"
  billing_mode                = "PAY_PER_REQUEST"
  stream_enabled              = false
  hash_key                    = "Id"

  # TODO: Couldn't find a Config rule for this. Maybe try custom?
  deletion_protection_enabled = false

  # Initialized as "false" to trigger Config
  server_side_encryption {
    enabled = false
  }

  # Initialized as "false" to trigger Config
  point_in_time_recovery {
    enabled = false
  }

  attribute {
    name = "Id"
    type = "S"
  }
}
