import json
import avro.schema
from avro.io import DatumReader

def validate_json(json_file_path, avro_schema_file_path):
    # Load the JSON file
    with open(json_file_path, 'r') as json_file:
        json_data = json.load(json_file)

    print("JSON data:")
    print(json.dumps(json_data, indent=2))

    print("Avro schema:")
    with open(avro_schema_file_path, 'r') as avro_schema_file:
        print(avro_schema_file.read())


    # Parse the Avro schema
    with open(avro_schema_file_path, 'r') as avro_schema_file:
        avro_schema = avro.schema.parse(avro_schema_file.read())

    # Create a DatumReader with the Avro schema
    datum_reader = DatumReader(avro_schema)

    try:
        # Validate the JSON data against the Avro schema
        datum_reader.read(json_data)
        print("JSON data is valid against the Avro schema.")
    except Exception as e:
        print("JSON data is not valid against the Avro schema.")
        print(str(e))


if __name__ == "__main__":
    # accept args from command line
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--json_file_path", help="path to json file")
    parser.add_argument("--avro_schema_file_path", help="path to avro schema file")
    args = parser.parse_args()
    validate_json(args.json_file_path, args.avro_schema_file_path)
