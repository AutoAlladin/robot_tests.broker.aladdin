from datetime import datetime
import time
import urllib2


def dt(var_date): 
    poss=var_date.find('+')-1
        
    var_date=var_date[:poss]
    
    conv_dt = datetime.strptime(var_date, '%Y-%m-%dT%H:%M:%S.%f')
    date_str = conv_dt.strftime('%Y-%m-%d %H:%M:%S')
    return date_str

def get_local_tz():
    """Return offset of local zone from GMT, either at present or at time t."""
    # python2.3 localtime() can't take None
    t = time.time()

    if time.localtime(t).tm_isdst and time.daylight:
        return -time.altzone/3600
    else:
        return -time.timezone/3600

def convert_float_to_string(number):
    return format(number, '.2f')

def load_tender(url):
    return urllib2.urlopen(url).read()