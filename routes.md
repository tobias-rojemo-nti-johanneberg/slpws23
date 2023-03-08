# Main

# # GET /

> home page

# # GET /login

> login as existing user

# # GET /register

> register new user

# # POST /login

> login as existing user

# # POST /register

> register new user

# Characters

# # GET /characters

> all characters

# # GET /characters/:id

> specific character

# # GET /characters/tag/:id

> all characters with specific tag type

# # POST /characters

> create character

# # PATCH /characters/:id

> edit character if owner or admin

# # DELETE /characters/:id

> delete character if owner and character is private or unused or if admin

# Scripts

# # GET /scripts

> all scripts

# # GET /scripts/search/:query

> all scripts, filtered by query

# # GET /scripts/:id

> specific script

# # GET /scripts/:id/characters

> all characters in script

# # GET /scripts/:id/owner

> owner of specific script, specific user

# # GET /scripts/:id/source

> source of specific script if fork, else null

# # GET /scripts/:id/forks

> all forks of specific script

# # GET /scripts/:id/edits

> all edits of specific script from source script

# # GET /scripts/:id/edits/origin

> all edits of specific script from origin script

# # POST /scripts

> create script

# # PATCH /scripts/:id

> edit script if owner or admin

# # DELETE /scripts/:id

> delete script if owner and script is private or unforked or if admin

# # POST /scripts/:id/fork

> create script as fork of public script

# Users

# # GET /users

> all users

# # GET /users/search/:query

> all users, filtered by query

# # GET /users/:id

> specific user