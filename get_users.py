import json

def main():
    with open('user_roles.json') as f:
        userfile = json.load(f)
        for user in userfile['users']:
            print(user)

if __name__ == '__main__':
    main()