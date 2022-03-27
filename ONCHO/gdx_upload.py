#!/usr/bin/env python3
# File name: gdx_upload.py
# Author: jessica.chung@gatesfoundation.org
# Date: 16-feb-2022
# Description: Upload local file to a specified dataset in the Gates Data Exchange. 
# Prerequisites: 1) Install ckanapi, giftless_client 2) Update api_key parameter prior to running. 3) Obtain Dataset ID from target dataset on GDx prior. 
# Usage: python gdx_upload.py "/path/to/file" "gdx_dataset_id"


from ckanapi import RemoteCKAN
from giftless_client import LfsClient
import os
import sys
import argparse
import logging
from logging import critical, error, info, warning, debug

api_key = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKTVJSbVZlM0xHcTJuQ3NRT2U2bWU0R1ZRd1I2X0o3dzR1bnlYMnB2dzhjIiwiaWF0IjoxNjQ0MTY5NjM4fQ.ky1Ay-W05uExiGcphwbzcyZ7r8S8lsA56Yxdt2R-_10'
gdx_url = 'https://dataexchange.gatesfoundation.org'
gdx = RemoteCKAN(gdx_url, api_key )
lfs_server = gdx_url+'/resources/'

def parse_arguments():
    """Read arguments from a command line."""
    parser = argparse.ArgumentParser(description='Arguments get parsed via --commands')
    parser.add_argument("file_path", help = "required: Path to file to upload")
    parser.add_argument("dataset_id", help = "required: Dataset ID found on Data Exchange")
    parser.add_argument('-v', metavar='verbosity', type=int, default=2,
        help='Verbosity of logging: 0 -critical, 1- error, 2 -warning, 3 -info, 4 -debug')

    args = parser.parse_args()
    verbose = {0: logging.CRITICAL, 1: logging.ERROR, 2: logging.WARNING, 3: logging.INFO, 4: logging.DEBUG}
    logging.basicConfig(format='%(message)s', level=verbose[args.v], stream=sys.stdout)
    
    return args

def valid_dataset(dataset_id):
    """
    Check if dataset exists in GDx
    
    Returns GDx package object if exists, else exit
    
    """
    logging.info('Checking if dataset %s exists in GDx', dataset_id)
    try:
        return gdx.action.package_show(id=dataset_id)    
    except Exception as e:
        if e.args[0]=="Not found":
            logging.error('GDx Dataset ID not found. Please check ID and try again.')
        else:
            logging.error('API Token incorrect or incorrect permissions for provided dataset. Check API token and try again.')
        sys.exit()

def get_resource(dataset_id, file_path):
    """
    Check if file exists in provided dataset
    
    Returns GDx resource ID for file, else empty string
    
    """
    file_name = os.path.basename(file_path)
    package = valid_dataset(dataset_id)
    logging.info('Checking if file %s exists in dataset %s within GDx', file_name, dataset_id)
    resource_id = ''
    try:
        resource_id =list(filter(lambda r: r["name"] == file_name, package["resources"]))[0]["id"]
        logging.info('File exists in this dataset within GDx')
    except:
        logging.info('File does not exist in this dataset within GDx')
        pass
    return resource_id

def upload_resource(package_id, resource_id, file_path):
    """
    Upload file to given dataset in GDx. If resource id exists, overwrite existing file in GDx, else write new file
    
    Returns GDx resource object
    
    """
    logging.debug('Get an upload authorization token for the dataset')
    try: 
        authz = gdx.call_action(
            'authz_authorize',
            {'scopes' : [f'obj:gdx/{package_id}/*:write']}
            )
    except:
        logging.error('API Token incorrect or incorrect permissions for provided dataset. You must have Admin or Editor permissions to the dataset you are trying to edit')
        sys.exit()
    
    logging.debug('Create a lfs server client')
    client = LfsClient(lfs_server, authz['token'])

    logging.debug('Read the file and upload it using client.upload(...)')
    try: 
        with open(file_path, 'rb') as file_obj:
            res_attr = client.upload(file_obj, 'gdx', package_id) 
    except:
        logging.error('File %s not found', file_path)
        sys.exit()
        
    if resource_id:
            resource_dict = {'id': resource_id,\
                             'name' : os.path.basename(file_path),
                             'url' : os.path.basename(file_path),\
                             'sha256' : res_attr['oid'],
                             'size' : res_attr['size']}
            resource = gdx.action.resource_patch(**resource_dict)
            logging.info('Existing file %s updated in dataset with ID %s',os.path.basename(file_path),resource["id"])
    else:
        resource = gdx.action.resource_create(package_id = package_id,\
                                         name = os.path.basename(file_path),\
                                         url = file_path,
                                         lfs_prefix = f'gdx/{package_id}', # required
                                         url_type = 'upload', # required
                                         sha256 = res_attr['oid'],# required
                                         size = res_attr['size']# required
                                        )
        logging.info('File %s written to dataset with ID %s',os.path.basename(file_path),resource["id"])
    return resource

def main():
    args = parse_arguments()
    resource_id = get_resource(args.dataset_id, args.file_path)
    uploaded_resource = upload_resource(args.dataset_id, resource_id, args.file_path)

if __name__ == '__main__':
    main()
