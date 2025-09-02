#!/usr/bin/python

import argparse
from fileinput import filename
import json
import grpc
import time
import yaml

import pyvelociraptor
from pyvelociraptor import api_pb2
from pyvelociraptor import api_pb2_grpc


def run(config, query, env_dict):
    # Fill in the SSL params from the api_client config file. You can get such a file:
    # velociraptor --config server.config.yaml config api_client > api_client.conf.yaml
    creds = grpc.ssl_channel_credentials(
        root_certificates=config["ca_certificate"].encode("utf8"),
        private_key=config["client_private_key"].encode("utf8"),
        certificate_chain=config["client_cert"].encode("utf8"))

    # This option is required to connect to the grpc server by IP - we
    # use self signed certs.
    options = (('grpc.ssl_target_name_override', "VelociraptorServer",),)

    env = []
    for k, v in env_dict.items():
        env.append(dict(key=k, value=v))

    # The first step is to open a gRPC channel to the server..
    with grpc.secure_channel(config["api_connection_string"],
                             creds, options) as channel:
        stub = api_pb2_grpc.APIStub(channel)

        # The request consists of one or more VQL queries. Note that
        # you can collect artifacts by simply naming them using the
        # "Artifact" plugin.
        request = api_pb2.VQLCollectorArgs(
            max_wait=1,
            max_row=100,
            Query=[api_pb2.VQLRequest(
                Name="Test",
                VQL=query,
            )],
            env=env,
        )

        # This will block as responses are streamed from the
        # server. If the query is an event query we will run this loop
        # forever.
        for response in stub.Query(request):
            if response.Response:
                package = json.loads(response.Response)
                # print (package)

            elif response.log:
                # Query execution logs are sent in their own messages.
                print ("%s: %s" % (time.ctime(response.timestamp / 1000000), response.log))

            return package

class kwargs_append_action(argparse.Action):
    def __call__(self, parser, args, values, option_string=None):
        try:
            d = dict(map(lambda x: x.split('='),values))
        except ValueError as ex:
            raise argparse.ArgumentError(
                self, f"Could not parse argument \"{values}\" as k1=v1 k2=v2 ... format")

        setattr(args, self.dest, d)

def main():
    env = {}
    apifile = "G:\Velociraptor\SRL\clint_api_client.yaml"
    config = pyvelociraptor.LoadConfigFile(apifile)

    # print_users(config, env)
    # list_hunts(config, env)
    # print_srum(config, env)
    # print_ps(config, env)
    print_processlist(config,env)
    # print(run(config, "SELECT * FROM hunt_results()", env))


def list_hunts(config,env):
    # query = f"Select * from hunts()"
    query = f"SELECT hunt_id, hunt_description, artifacts FROM hunts()"
    response = run(config, query, env)
    for r in response:
        print (r)


def print_ps(config, env):
    huntId ="'H.e0ec34ca'"
    ArtifactName="'Windows.EventLogs.PowershellScriptblock'"
    query = "SELECT * from hunt_results()"
    #  query = f"SELECT * FROM hunt_results(hunt_id={huntId}, artifact={ArtifactName})"
    
    response = run(config, query, env)
    print (response)


def print_processlist(config, env):
    huntId ="'H.7e72f212'"
    ArtifactName="'Windows.System.Pslist'"
    # query = "SELECT * from hunt_results()"
    query = f"SELECT * FROM hunt_results(hunt_id={huntId}, artifact={ArtifactName})"
    
    response = run(config, query, env)
    for r in response:
        CommandLine = r['CommandLine']
        Path = r['Exe']
        Fqdn = r['Fqdn']
        Hash = r['Hash']
        # print (r)
        print (Hash)
        # print (f"{Path},{CommandLine},{Fqdn}")



#Doesnt work
def print_srum(config, env):
    huntId ="'H.724961cd'"
    ArtifactName="'Windows.Forensics.SRUM/Execution Stats'"
    query = f"SELECT * FROM hunt_results(hunt_id={huntId}, artifact={ArtifactName})"
    
    response = run(config, query, env)
    print (response)
    # for r in response:
        # print (r)
        # print (f"{name},{directory},{uuid},{fqdn}")


def print_users(config, env):
    huntId ="'H.ce37a047'"
    ArtifactName="'Windows.Sys.Users'"
    query = f"SELECT Name,Directory,UUID,Fqdn FROM hunt_results(hunt_id={huntId}, artifact={ArtifactName})"
    
    response = run(config, query, env)
    for r in response:
        name = r['Name']
        uuid = r['UUID']
        fqdn = r['Fqdn']
        directory = r['Directory']
        print (f"{name},{directory},{uuid},{fqdn}")

if __name__ == '__main__':
    main()




    # def template(config, env):
    # huntId ="'H.ce37a047'"
    # ArtifactName="'Windows.Sys.Users'"
    # # query = f"SELECT * FROM hunt_results(hunt_id={huntId}, artifact={ArtifactName})"

    # query = f"SELECT Name,UUID,Fqdn FROM hunt_results(hunt_id={huntId}, artifact={ArtifactName})"
    
    # response = run(config, query, env)
    # for r in response:
    #     print (r)