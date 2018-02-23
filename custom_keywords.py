#!/usr/bin/env python
# -*- coding: utf-8 -*- 
from robot.libraries.BuiltIn import BuiltIn
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.support.select import Select
from selenium.webdriver.support.wait import WebDriverWait
from datetime import datetime
from time import sleep
import time
import urllib2

apiUrl="http://192.168.95.153:92"


def get_aladdin_formated_date(var_date): 
    poss = var_date.find('+')-1
        
    var_date = var_date[:poss]
    
    conv_dt = datetime.strptime(var_date, '%Y-%m-%dT%H:%M:%S.%f')
    date_str = conv_dt.strftime('%d-%m-%Y %H:%M:%S')
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

def waitFadeIn():
    try:
        WebDriverWait(get_webdriver(), 20).until( expected_conditions.invisibility_of_element_located ((By.XPATH, "//div[@class='page-loader animated fadeIn']")))
    except:
        pass

def get_webdriver():
    se2lib = BuiltIn().get_library_instance('Selenium2Library')
    return se2lib._current_browser()

def set_mnn_and_other(item):
    drv = get_webdriver()
    
    if item["classification"]["id"][0:3]=="336":
        inn = item["additionalClassifications"][0]["id"].capitalize()
        atc = item["additionalClassifications"][1]["id"]
        #inn

        btn_mnn = WebDriverWait(drv, 10).until(
                expected_conditions.visibility_of_element_located((By.XPATH,"//button[contains(@id,'inn_click_')]")))
        btn_mnn.click()

        txt_search = WebDriverWait(drv, 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"search-classifier-text")))
        txt_search.send_keys(inn)
        btn_add =  WebDriverWait(drv, 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"add-classifier")))
        btn_add.click()

        WebDriverWait(drv, 10).until(
            expected_conditions.visibility_of_element_located((By.XPATH,"//button[contains(@id,'atc_click_')]")))

        #atc
        btn_atc = WebDriverWait(drv, 10).until(
            expected_conditions.visibility_of_element_located((By.XPATH,"//button[contains(@id,'atc_click_')]")))
        btn_atc.click()
        txt_search = WebDriverWait(drv, 10).until(
            expected_conditions.visibility_of_element_located((By.ID, "search-classifier-text")))
        txt_search.send_keys(atc)
        btn_add = WebDriverWait(drv, 10).until(
            expected_conditions.visibility_of_element_located((By.ID, "add-classifier")))
        btn_add.click()

        WebDriverWait(drv, 10).until(
                expected_conditions.visibility_of_element_located((By.XPATH,"//button[contains(@id,'inn_click_')]")))

    dkpp = "000" #item["additionalClassifications"][0]["id"]
    #dkpp
    
    btn_other = WebDriverWait(drv, 10).until(
         expected_conditions.visibility_of_element_located((By.XPATH,"//button[contains(@id,'btn_otherClassifier')]")))
    btn_other.click()

    txt_search = WebDriverWait(drv, 10).until(
        expected_conditions.visibility_of_element_located((By.ID,"search-classifier-text")))

    txt_search.send_keys(dkpp)

    btn_add =  WebDriverWait(drv, 10).until(
        expected_conditions.visibility_of_element_located((By.ID,"add-classifier")))
    btn_add.click()

    WebDriverWait(drv, 10).until(
        expected_conditions.visibility_of_element_located((By.XPATH,"//input[contains(@id,'otherClassifier')]")))

def set_aladdin_data(tender_data):
    for i in tender_data["data"]["items"]:
        for d in i["additionalClassifications"]:
            if i["classification"]["id"][0:3]!="336":                
                d["id"]="000"
                d["description"]="Спеціальні норми та інше"


def search_tender(username,tender_uaid,home):
    get_webdriver().get(home)

    urllib2.urlopen(apiUrl+"/api/sync/purchase/purchaseID/purchaseID="+tender_uaid+"?test=true").read()
    btnSearch = WebDriverWait(get_webdriver(), 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"butSimpleSearch")))

    select_searchType = WebDriverWait(get_webdriver(), 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"searchType")))

    txt_search = WebDriverWait(get_webdriver(), 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"findbykeywords")))

    Select(select_searchType).select_by_value("1")
    txt_search.clear()
    txt_search.send_keys(tender_uaid)

    link = None
    for i in range(10):
        try:
            btnSearch.click()            
            link = WebDriverWait(get_webdriver(), 5).until(
                    expected_conditions.presence_of_element_located((By.XPATH,"//span[contains(text(),'"+tender_uaid+"')]/../a")))
        except Exception as e:
            print e
            pass

        if link is None:
            sleep(10)            
        else:            
            break

    url = get_webdriver().execute_script("return $(\"a[id*='href-purchase']\").attr('href')")
    get_webdriver().get(home+"/"+url)

    WebDriverWait(get_webdriver(), 20).until(
                    expected_conditions.visibility_of_element_located((By.ID,"purchaseGuid")))


