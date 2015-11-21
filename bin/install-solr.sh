#!/usr/bin/env bash

SOLR_PORT=${SOLR_PORT:-8983}

download() {
    echo "Downloading solr from $1..."
    curl -s $1 | tar xz
    echo "Downloaded"
}

is_solr_up(){
    http_code=`echo $(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$SOLR_PORT/solr/admin/ping")`
    return `test $http_code = "200"`
}

wait_for_solr(){
    while ! is_solr_up; do
        sleep 3
    done
}

run() {
    echo "Starting solr on port ${SOLR_PORT}..."

    cd $1/example
    if [ $DEBUG ]
    then
        java -Djetty.port=$SOLR_PORT -jar start.jar &
    else
        java -Djetty.port=$SOLR_PORT -jar start.jar > /dev/null 2>&1 &
    fi
    wait_for_solr
    cd ../../
    echo "Started"
}

post_some_documents() {
    java -Dtype=application/json -Durl=http://localhost:$SOLR_PORT/solr/update/json -jar $1/example/exampledocs/post.jar $2
}


download_and_run() {
   
     
    url="http://archive.apache.org/dist/lucene/solr/3.6.2/apache-solr-3.6.2.tgz"
    dir_name="apache-solr-3.6.2"
    dir_conf="conf/"
           
    download $url

    # copies custom configurations
    for file in $SOLR_CONFS
    do
        if [ -f $file ]
        then
            cp $file $dir_name/example/solr/$dir_conf
            echo "Copied $file into solr conf directory."
        fi
    done

    # Run solr
    run $dir_name $SOLR_PORT

    # Post documents
    if [ -z "$SOLR_DOCS" ]
    then
        echo "$SOLR_DOCS not defined, skipping initial indexing"
    else
        echo "Indexing $SOLR_DOCS"
        post_some_documents $dir_name $SOLR_DOCS
    fi
}

download_and_run $SOLR_VERSION
