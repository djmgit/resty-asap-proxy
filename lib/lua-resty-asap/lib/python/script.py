"""
Module to generate asap token using asap issuer and asap private key
"""

import sys
from atlassian_jwt_auth.contrib.requests import JWTAuth
from atlassian_jwt_auth.key import DataUriPrivateKeyRetriever
from atlassian_jwt_auth.signer import JWTAuthSigner

class R:
    headers = {}

def generate_asap_token(asap_issuer: str, asap_private_key: str, asap_audience: str):
    signer = JWTAuthSigner(asap_issuer, DataUriPrivateKeyRetriever(asap_private_key))
    return JWTAuth(signer, asap_audience)

def get_asap_params():
    line = ""
    for l in sys.stdin:
        line = l.strip()
    asap_params = line.split()
    return asap_params[0].strip(), asap_params[1].strip(), asap_params[2].strip()

def main():
    asap_issuer, asap_private_key, asap_audience = get_asap_params()
    jwt_auth = generate_asap_token(asap_issuer, asap_private_key, asap_audience)
    jwt_auth(R)
    jwt_token = R.headers["Authorization"].decode()
    return jwt_token

if __name__ == "__main__":
    print (main())