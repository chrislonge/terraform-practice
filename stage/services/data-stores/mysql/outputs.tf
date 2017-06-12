output "address" {
    value = "${aws_db_instance.mysql_db.address}"
}

output "port" {
    value = "${aws_db_instance.mysql_db.port}"
}