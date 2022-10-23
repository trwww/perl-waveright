#!/bin/bash

DBNAME=$1
DBUSER=$2
DBPASS=$3

mysqladmin --user=$2 --password="$DBPASS" drop   $DBNAME
mysqladmin --user=$2 --password="$DBPASS" create $DBNAME
mysql      --user=$2 --password="$DBPASS"        $DBNAME < WaveRight/sql/init.sql
