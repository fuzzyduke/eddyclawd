import paramiko

def deep_traefik_audit():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        commands = {
            "api_dump": 'docker exec traefik wget -qO- http://localhost:8080/api/rawdata',
            "logs_hello1": 'docker logs traefik 2>&1 | grep -i "hello1"',
            "curl_insecure": 'curl -skI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com',
            "http_check": 'curl -skI --resolve hello1.valhallala.com:80:167.86.84.248 http://hello1.valhallala.com'
        }
        
        for name, cmd in commands.items():
            print(f"=== {name} ===")
            si, so, se = ssh.exec_command(cmd)
            print(so.read().decode('utf-8'))
            print(se.read().decode('utf-8'))
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    deep_traefik_audit()
