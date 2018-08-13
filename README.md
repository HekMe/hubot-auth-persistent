# Hubot: hubot-auth-persistent

Assign roles to users and restrict command access in other scripts. (Tested on Hubot stackstorm module)

## Commands
`<user>` has `<role>` role - Assigns a role to a user

`<user>` doesn't have `<role>` role - Removes a role from a user

what roles does `<user>` have - Find out what roles a user has

what roles do I have - Find out what roles you have

who has `<role>` role - Find out who has the given role

list assigned roles - List all assigned roles

what is my name - Tells you your name from persistent storage

what is my id - tells you your id from persistent storage

## Installation

Clone **hubot-auth-persistent** to your `/hubot/node_modules` folder

Remove **.git** folder from `/hubot/node_modules/hubot-auth-persistent/(.git)`

Add **hubot-auth-persistent** to your `external-scripts.json`:

```json
["hubot-auth-persistent"]
```

Run `npm install` in root of your hubot

### ACL

Use `*` as wildcard for more commands

At least one record in **acl.json** is needed.

Add **acl.json** to to root folder of your hubot:

```json
[
{
  "role": "Role name",
  "description": "Role description",
  "commands": [
    "command 1",
    "command 2",
    "command 3 * 4"
  ]
}
]
```

Example:
```json
[{
  "role": "admin",
  "description": "alias1",
  "commands": [
    "admin test pikachu",
    "st2 list * actions"
  ]
}, {
  "role": "alias2",
  "description": "alias2",
  "commands": [
    "alias2 fmt1 {{param1}} {{param2}}",
    "alias2 fmt2 {{param1}} some more words",
    "alias1 fmt1 {{param}} breaking words {{param2=default}}"
  ]
}, {
  "role": "alias3",
  "description": "alias3",
  "commands": [
    "st2 list {{ limit=10 }} actions"
  ]
}, {
  "role": "testAdmin",
  "description": "alias4",
  "commands": [
    "test pokemon",
    "st2 free"
  ]
}, {
  "role": "test",
  "description": "test",
  "commands": [
    "st2 list *"
  ]
}]

```
### Roles

`st2admin` is default superuser role and has access to everything

At least one record in **roles.json** is needed.

Add **roles.json** to to root folder of your hubot:

```json
[
{
    "role": "st2admin",
    "users": [
        "slack user id"
    ]
}
]
```

Example:
```json
[
    {
        "role": "st2admin",
        "users": [
            "U80PZKFCJ"
        ]
    },
    {
        "role": "admin",
        "users": [
            "asdf",
            "U80PZKFCJ"
        ]
    },
    {
        "role": "test",
        "users": [
            "asdf1"
        ]
    }
]
```

## Usage

remove `"use strict";` from beginning of your stackstorm.js file  

### Replace in Stackstorm.js
```coffee
robot.respond(/([\s\S]+?)$/i, (msg) => {
...
}
```
with
```coffee
robot.respond(/([\s\S]+?)$/i, (msg) => {
    var command, result, command_name, format_string, action_alias;

    // Normalize the command and remove special handling provided by the chat service.
    // e.g. slack replace quote marks with left double quote which would break behavior.
    command = formatter.normalizeCommand(msg.match[1]);

    result = command_factory.getMatchingCommand(command);

    if (result == null || result == "") {
      // No command found
      msg.reply("No command found");
      return;
    }

    command_name = result[0];
    format_string = result[1];
    action_alias = result[2];
    user = robot.brain.userForName(msg.message.user.name);

    if(robot.auth.isAdmin(user)){
      executeCommand(msg, command_name, format_string, command, action_alias);
    } else {
      robot.logger.info("user> " + user)
      var uCommands = [],
          roles = robot.auth.userRoles(user),
          fs = require('fs'),
          acl = JSON.parse(fs.readFileSync(process.cwd() + '/acl.json', 'utf8'));

      for (var i = 0; i < roles.length; i++) {
        for (var j = 0; j < acl.length; j++) {
          if(roles[i] === acl[j].role){
            uCommands.push(acl[j].commands);
          }
        }
      }
      function matchRuleShort(str, rule) {
        return new RegExp("^" + rule.split("*").join(".*") + "$").test(str);
      }
      console.log(uCommands);
      uCommands = [...new Set(uCommands.map(a => a))];
      if(!uCommands.length == 0){
        for (var i = 0; i < uCommands.length; i++) {
          for(var j = 0; j < uCommands[i].length; j++)
          {
            if(matchRuleShort(command, uCommands[i][j])){
              CanDo = 1;
              Break;
            } else {
              robot.logger.info("cmd>" + uCommands[i][j] + " : " + command)
              CanDo = 0;
            }
          }
        }
        if(CanDo != 1){
          msg.reply("Sorry. You don't have appropriate role to do that.");
          CanDo = 0;
        } else {
          executeCommand(msg, command_name, format_string, command, action_alias);
        }
      } else {
        msg.reply("Error. User doesn't have any role nor any commands assigned")
      }
    }
  });
```
### Example Interaction
```
user2>> hubot some command
hubot>> Access Denied. You need role some-role to perform this action.
user1>> hubot user2 has some-role role
hubot>> OK, user2 has the some-role role.
user2>> hubot some command
hubot>> Command done!
```

