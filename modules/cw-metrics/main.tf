resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "AuthorizationFailures"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = var.cloudtrail_cloudwatch_group_name

  metric_transformation {
    name      = "AuthorizationFailureCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

# TODO: Implement the Alarm
