#!/bin/bash

DBHOST=$1
DBPORT=$2
DBNAME=$3
DBUSER=$4
DBPASS=$5

mysqladmin --host=$DBHOST --port=$DBPORT --user=$DBUSER --password="$DBPASS" drop -f $DBNAME
mysqladmin --host=$DBHOST --port=$DBPORT --user=$DBUSER --password="$DBPASS" create  $DBNAME
mysql      --host=$DBHOST --port=$DBPORT --user=$DBUSER --password="$DBPASS"         $DBNAME < waveright/core/sql/init.sql
