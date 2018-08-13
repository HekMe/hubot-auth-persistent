# Description
#   Assign roles to users and restrict command access in other scripts.
#
# Configuration:
#   HUBOT_AUTH_ROLES - A list of roles with a comma delimited list of user ids
#
# Commands:
#   hubot <user> has <role> role - Assigns a role to a user
#   hubot <user> doesn't have <role> role - Removes a role from a user
#   hubot what roles does <user> have - Find out what roles a user has
#   hubot what roles do I have - Find out what roles you have
#   hubot who has <role> role - Find out who has the given role
#   hubot list assigned roles - List all assigned roles
#
# Notes:
#   * Call the method: robot.auth.hasRole(msg.envelope.user,'<role>')
#   * returns bool true or false
#
#   * the 'admin' role can only be assigned through the environment variable and
#     it is not persisted
#   * roles are all transformed to lower case
#
#   * The script assumes that user IDs will be unique on the service end as to
#     correctly identify a user. Names were insecure as a user could impersonate
#     a user

fs = require 'fs'
process = require 'process'

admins = []
role_list = JSON.parse(fs.readFileSync(process.cwd() + '/roles.json', 'utf8'))

module.exports = (robot) ->
  class Auth

    # admin role is not persistent. List of user IDs who have admin role
    # unless config.admin_list?
    #   robot.logger.warning 'The HUBOT_AUTH_ADMIN environment variable not set'
    # unless config.role_list?
    #   robot.logger.warning 'The HUBOT_AUTH_ROLES environment variable not set'
    #
    # if config.admin_list?
    #   admins = config.admin_list.split ','
    # else
    #   admins = []
    #
    # if config.role_list?
    #   roles = config.role_list.split ','
    # else
    #   roles = []

    getRoleList: () ->
      JSON.parse(fs.readFileSync(process.cwd() + '/roles.json', 'utf8'))

    fetchAllRoles: () ->
      unless robot.brain.get('roles')
        robot.brain.set('roles', {})
      robot.brain.get('roles')

    isAdmin: (user) ->
      if typeof user is 'string'
        #robot.logger.warning("isAdmin: " + JSON.stringify(user))
        @hasRole(user, 'st2admin')
      else
        #robot.logger.warning("isAdmin: " + JSON.stringify(user.id))
        @hasRole(user.id, 'st2admin')

    hasRole: (user, roles) ->
      userRoles = @userRoles(user)
      if userRoles?
        roles = [roles] if typeof roles is 'string'
        # robot.logger.info("--------------------")
        # robot.logger.warning("ROLES: " + roles)
        # robot.logger.warning("USER: " + JSON.stringify(user.id) + " : " + user.id + " admins: " + admins + " ROLES: " + roles + " userRoles: " + userRoles + " UserRole-in-admin: " + (user.id in admins))
        # robot.logger.info("--------------------")
        for role in roles
          # robot.logger.warning("rolename: " + role + " st2admin?: " + (role == "st2admin") + " asde: " + (role == "st2admin" and user.id in admins))
          return true if role == "st2admin" and user.id in admins
          return true if role in userRoles
      return false

    usersWithRole: (role) ->
      users = []
      for own key, user of robot.brain.users()
        if @hasRole(user, role)
          users.push(user.name)
      users

    userRoles: (user) ->
      if typeof user is 'string'
        robot.logger.warning("userRoles-user-string: " + user)
        @fetchAllRoles()[user] or []
      else
        robot.logger.warning("userRoles-user-object: " + user.id)
        @fetchAllRoles()[user.id] or []

    addRole: (user, newRole) ->
      # robot.logger.info("--------------------")
      # robot.logger.info("USER: " + user)
      # robot.logger.info("USER: " + user)
      # robot.logger.info("newRole: " + newRole)
      # robot.logger.info("isAdmin: " + @isAdmin(user))
      # robot.logger.info("isAdmin: " + @isAdmin(user))
      # robot.logger.info("roles: " + JSON.stringify(robot.brain.get('roles'), null, 4))
      unless typeof user is 'string'
        user = user.id
      userRoles = @userRoles(user)
      robot.logger.info("Now user " + JSON.stringify(user) + " has roles " + userRoles)
      userRoles.push newRole unless newRole in userRoles
      allNewRoles = @fetchAllRoles()
      allNewRoles[user] = userRoles
      robot.brain.set('roles', allNewRoles)

      robot.logger.warning("addRole: " + JSON.stringify(user) + " : " + JSON.stringify(allNewRoles[user]) + " getRoles" + JSON.stringify(robot.brain.get('roles')) + " allNewRoles> " + JSON.stringify(allNewRoles))

      # robot.logger.warning("fetchAllRoles: " + allNewRoles[user])
      # robot.logger.error("userRoles: " + userRoles)
      # robot.logger.info("--------------------")


    revokeRole: (user, newRole) ->
      if role == "st2admin"
        #admins = (u for u in admins when u != user)
        return
      # unless typeof user is 'string'
        # user = user.id
      # robot.logger.info("user> " + user.id)
      unless typeof user is 'string'
        user = user.id
      userRoles = @userRoles(user)

      # robot.logger.info("userRoles> " + userRoles)

      userRoles = (role for role in userRoles when role isnt newRole)

      # robot.logger.info("userRoles> " + userRoles)

      allNewRoles = @fetchAllRoles()

      # robot.logger.info("allNewRoles> " + JSON.stringify(allNewRoles))

      allNewRoles[user] = userRoles

      # robot.logger.info("allNewRoles[user] = userRoles>" + JSON.stringify(allNewRoles[user]) + " = " + userRoles)
      # robot.logger.info("allNewRoles> " + JSON.stringify(allNewRoles))
      # robot.logger.info("allNewRoles[user]> " + allNewRoles[user])

      robot.brain.set('roles', allNewRoles)

      robot.logger.info("robot.brain.get('roles')> " + JSON.stringify(robot.brain.get('roles')))

    getRoles: () ->
      result = []
      for own key,roles of @fetchAllRoles('roles')
        robot.logger.info(JSON.stringify({key}) + " : " + JSON.stringify({roles}))
        result.push role for role in roles unless role in result
      result

  robot.auth = new Auth

  # TODO: This has been deprecated so it needs to be removed at some point.
  # if config.admin_list?
  #   robot.logger.warning 'The HUBOT_AUTH_ADMIN environment variable has been deprecated in favor of HUBOT_AUTH_ROLES'
  #   admins = config.admin_list.split ','
  #   robot.logger.warning(admins)
  #   for id in config.admin_list.split ','
  #     robot.logger.warning({id}.id)
  #     robot.auth.addRole({ id }.id, 'st2admin')
  #     robot.logger.warning("isAdmin: " + robot.auth.isAdmin({id}.id))
  # else
  #   admins = []

  unless role_list?
    robot.logger.warning 'The HUBOT_AUTH_ROLES environment variable not set'
  else
    for i in role_list
      if typeof {i}.i.users is 'string'
        robot.logger.info("UserString: " + {i}.i.users)
        if {i}.i.role == 'st2admin'
          unless {i}.i.users in admins
            admins.push({i}.i.users)
            robot.logger.info("Adding " + {i}.i.users + " to admins")
        robot.auth.addRole({i}.i.users, {i}.i.role);
        robot.logger.info("Adding role " + {i}.i.role + " to user " + {i}.i.users)
      else
        for j in {i}.i.users
          #robot.logger.info {i}.i.role
          robot.logger.error {j}.j
          if {i}.i.role == 'st2admin'
            unless {j}.j in admins
              admins.push({j}.j)
              robot.logger.info("Adding " + {j}.j + " to admins")
          robot.auth.addRole({j}.j, {i}.i.role);
          robot.logger.info("Adding role " + {i}.i.role + " to user " + {j}.j)
  robot.respond /@?([^\s]+) ha(?:s|ve) (["'\w: -_]+) role/i, (msg) ->
    name = msg.match[1].trim()
    roles = []
    role_list = robot.auth.getRoleList()
    if name.toLowerCase() is 'i' then name = msg.message.user.name

    unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
      unless robot.auth.isAdmin msg.message.user
        msg.reply "Sorry, only admins can assign roles."
      else
        newRole = msg.match[2].trim().toLowerCase()

        user = robot.brain.userForName(name)
        return msg.reply "#{name} does not exist" unless user?

        if robot.auth.hasRole(user, newRole)
          msg.reply "#{name} already has the '#{newRole}' role."
        else if newRole is 'st2admin'
          msg.reply "Sorry, the 'admin' role can only be defined in the roles.json config."
        else
          for i in role_list
            roles.push({i}.i.role)
          if newRole in roles
            for i, index in role_list
              if newRole == {i}.i.role
                role_list[index].users.push(user.id)
          else
            role_list.push({
              role: newRole,
              users: user.id
            })
          #robot.logger.info(role_list)
          robot.auth.addRole user, newRole
          fs.writeFile(process.cwd() + '/roles.json', JSON.stringify(role_list, null, 4), 'utf8');
          msg.reply "OK, #{name} has the '#{newRole}' role."

  robot.respond /@?([^\s]+) (?:don['’]t|doesn['’]t|do not) have (["'\w: -_]+) role/i, (msg) ->
    name = msg.match[1].trim()
    roles = []
    role_list = robot.auth.getRoleList()
    if name.toLowerCase() is 'i' then name = msg.message.user.name

    unless name.toLowerCase() in ['', 'who', 'what', 'where', 'when', 'why']
      unless robot.auth.isAdmin msg.message.user
        msg.reply "Sorry, only admins can remove roles."
      else
        newRole = msg.match[2].trim().toLowerCase()

        user = robot.brain.userForName(name)
        return msg.reply "#{name} does not exist" unless user?

        if newRole is 'st2admin'
          msg.reply "Sorry, the 'admin' role can only be removed from the roles.json."
        else
          for i in role_list
            roles.push({i}.i.role)
          if newRole in roles
            for i, index in role_list
              if newRole == role_list[index].role
                if typeof role_list[index].users == 'string'
                  if user.id == role_list[index].users
                    role_list.splice(index, 1);
                else
                  for j, jndex in role_list[index].users
                    if user.id == {j}.j
                      role_list[index].users.splice(jndex, 1)
          else
            msg.reply "ERROR, role like '#{newRole}' doesn't exist."
          robot.logger.info(role_list)
          robot.auth.revokeRole user, newRole
          fs.writeFile(process.cwd() + '/roles.json', JSON.stringify(role_list, null, 4), 'utf8');
          msg.reply "OK, #{name} doesn't have the '#{newRole}' role."

  robot.respond /what roles? do(es)? @?([^\s]+) have\?*$/i, (msg) ->
    name = msg.match[2].trim()
    if name.toLowerCase() is 'i' then name = msg.message.user.name
    user = robot.brain.userForName(name)
    return msg.reply "#{name} does not exist" unless user?
    userRoles = (x for x in robot.auth.userRoles(user))
    #userRoles.unshift("st2admin") if robot.auth.isAdmin(user)

    if userRoles.length == 0
      msg.reply "#{name} has no roles."
    else
      msg.reply "#{name} has the following roles: #{userRoles.join(', ')}."

  robot.respond /who has (["'\w: -_]+) role\?*$/i, (msg) ->
    role = msg.match[1]
    userNames = robot.auth.usersWithRole(role) if role?

    if userNames.length > 0
      msg.reply "The following people have the '#{role}' role: #{userNames.join(', ')}"
    else
      msg.reply "There are no people that have the '#{role}' role."

  robot.respond /list assigned roles/i, (msg) ->
    unless robot.auth.isAdmin msg.message.user
      msg.reply "Sorry, only admins can list assigned roles."
    else
      roles = robot.auth.getRoles()
      if roles.length > 0
          msg.reply "The following roles are available: #{roles.join(', ')}"
      else
          msg.reply "No roles to list."
