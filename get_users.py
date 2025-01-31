import json

def main():
    with open('user_roles.json') as f:
        users = json.load(f)
        for user in users:
            print(user)

if __name__ == '__main__':
    main()