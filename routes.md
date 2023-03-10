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

# # GET /characters/:id/scripts

> all scripts with specific character

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

# # GET /scripts/:id

> specific script

# # GET /scripts/:id/characters

> all characters in script

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

# # GET /users/:id

> specific user

# # GET /users/:id/scripts

> all scripts made by specific user

# # GET /users/:id/characters

> all characters made by specific user