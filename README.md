# Dashboard for biological ontologies

The goal of this project is to create an interactive dashboard over OBO Foundry ontologies. This dahsboard is being developed to display information about ontologies such as various errors, metrics.
OBO Foundry has its own tool for computing number of metrics about a ontology, such as entity and axiom counts, qualitative information and more complex metrics aimed at informing ontology developers, or this tool can report on various issues that may provide problems for users such as classes with multiple labels.

The [RDF Indexer](https://github.com/datagov-cz/dashboard-indexer) tool was taken as a basis, which was expanded by our ontology **Dashboard plugin** for ontology processing and GraphDB for ontology data storing. This architecture has also been expanded with the **Ontology Metric Service**, which is independent.

# Installation

## Authentication

### 1. Create `.env` file

Create `.env` file in root directory of the project (same directory as "*docker-compose.yml*"). Insert folowing (**only
change variables in double asterisks `**var-name**`**):

    # OntologyDashboard
    # Name of compose cluster of containers
    COMPOSE_PROJECT_NAME=cluster-name
    KIBANA_SYSTEM_PASS=***pass***
    # Kibana user credentials for indexer
    INDEXER_USERNAME=***indexer***
    INDEXER_PASSWORD=***indexer***
    # Kibana user credentials for public account (auto-sign-in user)
    PUBLIC_USERNAME=public
    PUBLIC_PASSWORD=public
    # Ports 
    ELASTICSEARCH_PORT=9200
    KIBANA_PORT=5601
    # Kibana port with auto-sign-in (for public display)
    PUBLIC_KIBANA_PORT=6601
    INDEXER_PORT=8080
    GRAPHDB_PORT=7200
    ONTOLOGY_METRICS_PORT=8081
    # Additional settings
    DASHBOARD_PLUGIN=true
    USE_BASE_VARIANT=true
    JAVA_MAX_MEMORY=8192M
    JAVA_INIT_MEMORY=2048M
    INDEXER_MAX_CONCURRENT_HARVESTS=3
    KIBANA_BASE_PATH=/
    ELASTIC_STACK_VERSION=7.16.0
    NGINX_VERSION=1.21.4
    CERTS_DIR=/usr/share/elasticsearch/config/certificates

    #OntologyMetrics
    THREADPOOL_SIZE=1
    GRAPHDB_REPOSITORY=http://host.docker.internal:7200/repositories/ontologiesmetrics
    ELASTICSEARCH_HOSTNAME=host.docker.internal
    ELASTICSEARCH_SCHEME=https
    #name of index in which data for dashboard will be stored
    ELASTICSEARCH_INDEX=ontologiesmetrics
    ELASTICSEARCH_APIKEY=***apikey***

### 2. Create docker containers

Optional ( You can change settings in *docker-compose-auth.yml* file. )

Create certificate:

    docker-compose -f create-certs.yml run --rm create_certs

Create Nginx config:

	docker-compose -f create-nginx-conf.yml run --rm create_nginx_conf

Then create images and start containers with command:

	docker-compose -f docker-compose-auth.yml up -d --build

### 3. Initialize passwords in ES

Create initial passwords for Elasticsearch:

	docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://localhost:9200"

Save generated passwords (mainly `elastic` and `kibana_system`).

### 4. Edit .env file

Edit `.env` by changing variables in **triple asterisks**. `KIBANA_SYSTEM_PASS` to saved password `kibana_system` and
come up with user credentials for "*Indexer*". **(Special characters are not allowed in credentials.)**

### 5. Recreate docker containers

Recreate kibana and indexer containers.

	docker-compose -f docker-compose-auth.yml up -d --build

### 6. Setup Kibana

#### First login

Login to Kibana (default https://localhost:5601).

- Username: elastic
- Password: [saved_elastic_pass]

#### Create Elastic API key 

Go to Menu -> Stack Management -> Security -> API keys and generate Elastic API key. 

Edit `.env` by changing variable ELASTICSEARCH_APIKEY in **triple asterisks**

Recreate ontology metrics dashboard app.

	docker-compose -f docker-compose-auth.yml up -d --build


### Create superuser

Create you own *user* with `superuser` role in `side menu > Stack Management > Users (under Security)` and
click `Create user`. Then relogin with your new superuser.

#### Create user for indexer

Create new role (in `side menu > Stack Management > Roles (under Security)` and click `Create role`):

1. Set `Role name` to "*indexer*"
2. ElasticSearch
    - Cluster privliges - `manage`
    - Index privliges
        - Indeces - `*`
        - Priviliges - `create`, `create_index`, ` manage`, `read`
3. Kibana
    - Click "*Add Kibana privileges*"
        - Spaces - `* All Spaces`
        - Privileges for all features - set to `Customize`
        - Customize feature privileges
            - click `Bulk actions > None`
            - set `Analytics > Dashboard` to `Read`
            - now all *feature privileges* should be `None` except for the `Analytics > Dashboard`
        - Click "*Create global privileges*"
4. Click "*Create role*"

Create user with credentials from `.env` for indexer (`INDEXER_USERNAME` and `INDEXER_PASSWORD`) and assign
role `indexer`.

#### Create public user

Create new role (in `side menu > Stack Management > Roles (under Security)` and click `Create role`):

1. Set `Role name` to "*public*"
2. ElasticSearch
    - Index privliges
        - Indeces - `*`
        - Priviliges - `read`, `view_index_metadata`
3. Kibana
    - Click "*Add Kibana privileges*"
        - Spaces - select what you want
        - Privileges for all features - set to `Customize`
        - Customize feature privileges
            - click `Bulk actions > None`
            - set `Analytics > Dashboard`, `Analytics > Discover`, `Analytics > Canvas`, `Analytics > Maps`
              and `Management > Saved Objects Management` to `Read`
        - Click "*Create global privileges*"
4. Click "*Create role*"

Create user with credentials from `.env` for indexer (`PUBLIC_USERNAME` and `PUBLIC_PASSWORD`) and assign role `public`.

## Importing dashboards to Kibana (OntologyMetrics)
File /kibana/dashboards.ndjson contains predefined dashboards ready-to-import into Kibana.
(Menu -> Stack Management -> Kibana -> Saved objects -> Import)
These files import dashboards and index patterns into Kibana. Single ontology metrics dashboard wouldn't work with integrated searchbar.
To insert it manually, you have to go to the dashboard itself.
(Menu -> Dashboards -> Single ontology metrics -> Edit -> Add from library -> Ontology searchbar)
The searchbar will then occur at the bottom of dashboard. Adjust it to your needs and then tap Save in the top right corner.

## Invocation of ontology procession (OntologyMetrics)
The system processes a catalog of OBO ontologies weekly. It exposes REST api on the specified port, with generated Swagger UI, through which procession of ontologies can be invoked.
You can submit any web-available ontology,
but this feature has not been properly tested and the results won't
appear in the Kibana dashboard, but only in a named graph in GraphDB ( default http://localhost:7200).
