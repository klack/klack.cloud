import os
import base64
import hashlib
from hashlib import pbkdf2_hmac
import argparse

# Function to generate PBKDF2 hash
def generate_password_pbkdf2(password):
    # Define parameters
    salt = os.urandom(16)  # 16-byte salt
    iterations = 100000
    dklen = 64  # Length of the derived key (64 bytes)
    
    # Generate PBKDF2 hash
    pbkdf2_hash = pbkdf2_hmac('sha512', password.encode('utf-8'), salt, iterations, dklen)

    # Convert salt and hash to Base64
    salt_base64 = base64.b64encode(salt).decode('utf-8')
    pbkdf2_hash_base64 = base64.b64encode(pbkdf2_hash).decode('utf-8')

    # Format as @ByteArray(salt:hash)
    password_pbkdf2 = f"@ByteArray({salt_base64}:{pbkdf2_hash_base64})"
    
    return password_pbkdf2

# Set up argument parser
def main():
    parser = argparse.ArgumentParser(description='Generate qBittorrent Password_PBKDF2')
    parser.add_argument('password', type=str, help='Password to hash')

    # Parse arguments
    args = parser.parse_args()
    
    # Generate PBKDF2 password hash
    password_pbkdf2 = generate_password_pbkdf2(args.password)
    print(password_pbkdf2)

if __name__ == "__main__":
    main()
