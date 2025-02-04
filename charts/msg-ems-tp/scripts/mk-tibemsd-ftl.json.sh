#!/bin/bash

# Copyright (c) 2023 Cloud Software Group, Inc. All Rights Reserved. Confidential and Proprietary.

outfile=${1:-tibemsd-ftl.json}
srvBase="${MY_POD_NAME%-*}"
svcname="${srvBase/-ftl/-ems/}"
namespace=$MY_NAMESPACE
realmPort="${FTL_REALM_PORT-9013}"
emsTcpPort="${EMS_TCP_PORT:-9011}"
emsSslPort="${EMS_SSL_PORT:-9012}"
subData="/data"
pstoreData="/data"
# loglevel=${FTL_LOGLEVEL:-"info;quorum:debug"}
loglevel=${FTL_LOGLEVEL:-"info"}

# export LD_LIBRARY_PATH=/opt/tibco/ftl/lib
# /opt/tibco/ems/current-version/bin/tibemsjson2ftl -url "http://localhost:$ftlport" -json $initTibemsdJson
export insideSvcHostPort="${svcname}.${namespace}.svc:${emsTcpPort}"
cat - <<EOF > $outfile
{
  "acls":[],
  "bridges":[],
  "channels":[],
  "durables":[],
  "factories": [ 
    {
      "jndinames":[],
      "name":"ConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"generic",
      "url":"tcp:\/\/$emsTcpPort"
    },
    {
      "jndinames":[],
      "name":"FTConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"generic",
      "url":"tcp:\/\/$insideSvcHostPort,tcp:\/\/$insideSvcHostPort",
      "reconnect_attempt_count":"100",
      "reconnect_attempt_delay":"5000",
      "reconnect_attempt_timeout":"5000"
    },
    {
      "jndinames":[],
      "name":"GenericConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"generic",
      "url":"tcp:\/\/$emsTcpPort"
    },
    {
      "jndinames":[],
      "name":"TopicConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"topic",
      "url":"tcp:\/\/$emsTcpPort"
    },
    {
      "jndinames":[],
      "name":"QueueConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"queue",
      "url":"tcp:\/\/$emsTcpPort"
    },
    {
      "jndinames":[],
      "name":"FTTopicConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"topic",
      "url":"tcp:\/\/$insideSvcHostPort,tcp:\/\/$insideSvcHostPort"
    },
    {
      "jndinames":[],
      "name":"FTQueueConnectionFactory",
      "ssl":{
        "ssl_issuer_list":[],
        "ssl_trusted_list":[]
      },
      "type":"queue",
      "url":"tcp:\/\/$insideSvcHostPort,tcp:\/\/$insideSvcHostPort"
    }
  ],
  "groups":[
    {
      "description":"Administrators",
      "members":[
        {
          "name":"admin"
        }
      ],
      "name":"\$admin"
    }
  ],
  "model_version":"1.0",
  "queues":[
    {
      "expiration":"4day",
      "maxbytes":"4GB",
      "name":">",
      "secure":true,
      "store":"\$sys.failsafe"
    }
  ],
  "routes":[],
  "stores":[
          {
            "name":"\$sys.meta",
            "type":"ftl"
          },
          {
            "name":"\$sys.failsafe",
            "type":"ftl"
          },
          {
            "name":"\$sys.nonfailsafe",
            "type":"ftl"
          }
        ],
  "tibemsd":{
    "always_exit_on_disk_error":true,
    "authorization":false,
    "console_trace": "DEFAULT,+CONNECT",
    "flow_control":false,
    "handshake_timeout":60,
    "destination_backlog_swapout":"20000",
    "large_destination_memory":"3200MB",
    "max_client_msg_size":"2MB",
    "max_connections":"3000",
    "max_msg_memory":"8GB",
    "max_stat_memory":"64MB",
    "msg_swapping":true,
    "network_thread_count":3,
    "rate_interval":3,
    "reserve_memory":"32MB",
    "routing":false,
    "server":"$srvBase",
    "server_heartbeat_client":5,
    "server_rate_interval":1,
    "server_timeout_client_connection":16,
    "client_heartbeat_server": 5,
    "client_timeout_server_connection":16,
    "disconnect_non_acking_consumers":true,
    "ssl":{
      "ssl_cert_user_specname":"CERTIFICATE_USER",
      "ssl_issuer_list":[],
      "ssl_password":"\$man\$WjtSRCpaXu7hoTkDlcEPr6KNKRr",
      "ssl_server_identity":".\/certs\/samples\/server.cert.pem",
      "ssl_server_key":".\/certs\/samples\/server.key.pem",
      "ssl_trusted_list":[
      ]
    },
    "statistics_cleanup_interval":30,
    "statistics":true
  },
  "tibrvcm":[],
  "topics":[
    {
      "expiration":"4day",
      "maxbytes":"4GB",
      "name":">",
      "secure":true,
      "store":"\$sys.failsafe"
    }
  ],
  "transports":[],
  "users":[
    {
      "description":"Administrator",
      "name":"admin",
      "password":null
    },
    {
      "description":"server-user",
      "name":"$srvBase",
      "password":null
    }
  ]
}

EOF
