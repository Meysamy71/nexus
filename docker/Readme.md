### Execute the compose file using Docker compose command to start Nexus Container


`docker compose up -d`

---

### Show default login password


`docker exec -it nexus cat /nexus-data/admin.password`
