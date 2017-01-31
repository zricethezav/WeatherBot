import pygeohash as pgh
import redis
import sys

def marshal_wx(wx_csv_filename):
    # TODO:
    # - parse hour
    # - iterate through product
    # - read csvs and throw into redis
    # - delete csv
    print wx_csv_filename


if __name__ == "__main__":
    marshal_wx(sys.argv[1])
    

