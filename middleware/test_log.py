# REST API Test Results
RESULT = '''
Host: https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io
Graph: CargoNetwork
Secret: 8a1edqgs...

=== Test 1: /api/ping ===
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io/api/ping: 200 - {"error":false,"message":"pong","results":null}
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io:9000/api/ping: FAILED - HTTPSConnectionPool(host='tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io', port=9000): Max retries exceeded with url: /api/ping (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x0000016E2A76D810>, 'Connection to tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io timed out. (connect timeout=10)'))

=== Test 2: Request token ===
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io/requesttoken: 404 - {"error":true,"message":"Route /requesttoken not found.","results":null}
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io:9000/requesttoken: FAILED - HTTPSConnectionPool(host='tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io', port=9000): Max retries exceeded with url: /requesttoken (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x0000016E2A76C190>, 'Connection to tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io timed out. (connect timeout=10)'))

=== Test 3: Echo with bearer ===
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io/echo/CargoNetwork: 404 - {"error":true,"message":"Route /echo/CargoNetwork not found.","results":null}
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io:9000/echo/CargoNetwork: FAILED - HTTPSConnectionPool(host='tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io', port=9000): Max retries exceeded with url: /echo/CargoNetwork (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x0000016E2A76E490>, 'Connection to tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io timed out. (connect timeout=10)'))
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io/echo: 404 - {"error":true,"message":"Route /echo not found.","results":null}
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io:9000/echo: FAILED - HTTPSConnectionPool(host='tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io', port=9000): Max retries exceeded with url: /echo (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x0000016E2A76D310>, 'Connection to tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io timed out. (connect timeout=10)'))

=== Test 4: Version/endpoints ===
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io/api/version: 200 - {"error":false,"message":"","results":{"build_time":"Tue Sep 23 16:39:36 UTC 2025","git_commit":"a4abab1ff7c0a38c57ad2e2eba6bf4b813ee9da0","build_num":"4343","tigergraph_version":"4.2.2","is_graphstud
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io/endpoints/CargoNetwork: 404 - {"error":true,"message":"Route /endpoints/CargoNetwork not found.","results":null}
  https://tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io:14240/api/ping: FAILED - HTTPSConnectionPool(host='tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io', port=14240): Max retries exceeded with url: /api/ping (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x0000016E2A76C2D0>, 'Connection to tg-b26636d7-08d0-4a59-b546-80a3e9b40eeb.tg-2635877100.i.tgcloud.io timed out. (connect timeout=10)'))
'''
print(RESULT)
