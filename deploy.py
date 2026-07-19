#!/usr/bin/env python3
"""
Database deployment script for GTFS PostgreSQL database.
Deploys schema in the correct order: Extensions → Tables → Types → Functions → Procedures.
"""

import os
import sys
import psycopg2
from psycopg2.errors import Error as DatabaseError
import argparse
from pathlib import Path


def get_db_connection(host, port, user, password, dbname):
    """Establish a connection to the PostgreSQL database."""
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=dbname
        )
        return connection
    except DatabaseError as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)


def create_database_if_missing(host, port, user, password, dbname):
    """Create the database if it doesn't exist."""
    try:
        # Connect to the default 'postgres' database
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database='postgres'
        )
        connection.autocommit = True
        cursor = connection.cursor()
        
        # Check if database exists
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (dbname,))
        if cursor.fetchone() is None:
            print(f"Creating database '{dbname}'...")
            cursor.execute(f"CREATE DATABASE {dbname}")
            print(f"✓ Database '{dbname}' created")
        else:
            print(f"✓ Database '{dbname}' already exists")
        
        cursor.close()
        connection.close()
    except DatabaseError as e:
        print(f"Error creating database: {e}")
        sys.exit(1)


def execute_sql_file(connection, file_path):
    """Read and execute a single SQL file."""
    try:
        with open(file_path, 'r') as f:
            sql_content = f.read()
        
        cursor = connection.cursor()
        cursor.execute(sql_content)
        connection.commit()
        cursor.close()
        print(f"✓ {os.path.basename(file_path)}")
        return True
    except DatabaseError as e:
        print(f"✗ {os.path.basename(file_path)}: {e}")
        connection.rollback()
        return False
    except Exception as e:
        print(f"✗ {os.path.basename(file_path)}: {e}")
        return False


def deploy_database(base_path, connection):
    """Deploy the database in the correct order."""
    deployment_order = [
        ('Roles', None),  # All .sql files
        ('Extensions', 'all.sql'),
        ('Tables', None),  # All .sql files
        ('Types', None),   # All .sql files
        ('Functions', None),  # All .sql files
        ('Procedures', None),  # All .sql files
    ]
    
    total_files = 0
    successful_files = 0
    failed_files = []
    
    for category, specific_file in deployment_order:
        folder_path = os.path.join(base_path, category)
        
        if not os.path.exists(folder_path):
            print(f"⚠ {category} folder not found, skipping...")
            continue
        
        print(f"\n[{category}]")
        
        if specific_file:
            # Single file (Extensions)
            file_path = os.path.join(folder_path, specific_file)
            if os.path.exists(file_path):
                total_files += 1
                if execute_sql_file(connection, file_path):
                    successful_files += 1
                else:
                    failed_files.append(os.path.join(category, specific_file))
            else:
                print(f"✗ {specific_file} not found")
                failed_files.append(os.path.join(category, specific_file))
        else:
            # All .sql files in the folder
            sql_files = sorted([f for f in os.listdir(folder_path) if f.endswith('.sql')])
            
            if not sql_files:
                print(f"  No SQL files found in {category}")
                continue
            
            for sql_file in sql_files:
                file_path = os.path.join(folder_path, sql_file)
                total_files += 1
                if execute_sql_file(connection, file_path):
                    successful_files += 1
                else:
                    failed_files.append(os.path.join(category, sql_file))
    
    print(f"\n{'='*50}")
    print(f"Deployment complete: {successful_files}/{total_files} files executed successfully")
    
    if successful_files == total_files:
        print("✓ All files deployed successfully!")
        return True
    else:
        print(f"✗ {total_files - successful_files} file(s) failed:")
        for failed_file in failed_files:
            print(f"  - {failed_file}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Deploy GTFS PostgreSQL database schema'
    )
    parser.add_argument('--host', default='localhost', help='Database host (default: localhost)')
    parser.add_argument('--port', type=int, default=5432, help='Database port (default: 5432)')
    parser.add_argument('--user', default='postgres', help='Database user (default: postgres)')
    parser.add_argument('--password', default='', help='Database password')
    parser.add_argument('--dbname', default='gtfs', help='Database name (default: gtfs)')
    parser.add_argument('--path', default='.', help='Path to schema folder (default: current directory)')
    
    args = parser.parse_args()
    
    # Verify the path exists
    if not os.path.isdir(args.path):
        print(f"Error: Path '{args.path}' does not exist")
        sys.exit(1)
    
    # Check if required folders exist
    required_folders = ['Extensions', 'Tables', 'Types', 'Functions', 'Procedures', 'Roles']
    missing_folders = [f for f in required_folders if not os.path.isdir(os.path.join(args.path, f))]
    
    if missing_folders:
        print(f"Warning: Missing folders: {', '.join(missing_folders)}")
    
    print(f"Connecting to database: {args.user}@{args.host}:{args.port}/{args.dbname}")
    
    # Create database if it doesn't exist
    create_database_if_missing(args.host, args.port, args.user, args.password, args.dbname)
    
    connection = get_db_connection(args.host, args.port, args.user, args.password, args.dbname)
    
    try:
        success = deploy_database(args.path, connection)
        sys.exit(0 if success else 1)
    finally:
        connection.close()


if __name__ == '__main__':
    main()
