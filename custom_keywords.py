#!/usr/local/bin/python
# coding: utf-8

#-v BROKERS_PARAMS:{"aladdin":{"intervals":{"belowThreshold":{"enquiry":[0,60],"tender":[0,15]}}}}

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


def get_aladdin_formated_date(var_date=""):
    poss = var_date.find('+')-1
    #2018-05-24T00:00:0' does not match format '%Y-%m-%dT%H:%M:%S.%f
    var_date = var_date[:poss]

    if var_date.endswith("00:0"):
        var_date+="0"
        conv_dt = datetime.strptime(var_date, '%Y-%m-%dT%H:%M:%S')
    else:
        conv_dt = datetime.strptime(var_date, '%Y-%m-%dT%H:%M:%S.%f')

    date_str = conv_dt.strftime('%d-%m-%Y %H:%M:%S')
    return date_str

def get_aladdin_to_prozorro_date(var_date): 

    conv_dt = datetime.strptime( var_date.strip(), '%d-%m-%Y %H:%M:%S')
    date_str = conv_dt.strftime('%Y-%m-%dT%H:%M:%S')+".000000+0"+str(get_local_tz())+":00"
    return date_str

def get_local_tz():
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
        try:
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
        except:
            pass

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

    print urllib2.urlopen(apiUrl+"/api/sync/purchase/purchaseID/purchaseID="+tender_uaid+"?test=true").read()
    
    #select_searchType = WebDriverWait(get_webdriver(), 10).until(
    #            expected_conditions.visibility_of_element_located((By.ID,"searchType")))
    #Select(select_searchType).select_by_value("1")  https://test-gov.ald.in.ua/purchases#?page=1&filter=%7Ckeywords:UA-2018-03-02-000081-b:%7Csort:dateDown
    
    link = None
    for i in range(20):
        try:
            btnSearch = WebDriverWait(get_webdriver(), 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"butSimpleSearch")))

            txt_search = WebDriverWait(get_webdriver(), 10).until(
                expected_conditions.visibility_of_element_located((By.ID,"findbykeywords")))

            txt_search.clear()
            txt_search.send_keys(tender_uaid.strip())
            sleep(1)
            btnSearch.click()            
            link = WebDriverWait(get_webdriver(), 5).until(
                    expected_conditions.presence_of_element_located((By.XPATH,"//span[contains(text(),'"+tender_uaid+"')]/../a")))
        except Exception as e:
            print e
            pass

        if link is not None: break

    print get_webdriver().current_url
    url = get_webdriver().execute_script("return $(\"a[id*='href-purchase']\").attr('href')")
    get_webdriver().get(home+url)

    WebDriverWait(get_webdriver(), 20).until(
                    expected_conditions.visibility_of_element_located((By.ID,"purchaseGuid")))

def delete_feature(feature):
    WebDriverWait(get_webdriver(), 10).until(
    expected_conditions.visibility_of_element_located((By.ID,"purchaseEdit"))).\
    click()
    
    WebDriverWait(get_webdriver(), 10).until(
                    expected_conditions.visibility_of_element_located((By.ID,"features-tab"))).\
    click()

    btn=WebDriverWait(get_webdriver(), 10).until(
    expected_conditions.visibility_of_element_located((By.XPATH,
    "//div[contains(text(),'"+feature+"')]/../..//a[contains(@id,'updateOrCreateFeatureDeleteButton')]")))

    idd = btn.get_attribute("id") 

    get_webdriver().execute_script("$('#"+idd+"').click()")

    WebDriverWait(get_webdriver(), 10).until(
    expected_conditions.visibility_of_element_located((By.XPATH,
    "//div[@class='jconfirm-buttons']/button[1]"))).\
    click()

    WebDriverWait(get_webdriver(), 10).until(
    expected_conditions.visibility_of_element_located((By.ID,"basicInfo-tab"))).\
    click()

    WebDriverWait(get_webdriver(), 10).until(
    expected_conditions.visibility_of_element_located((By.ID,"movePurchaseView"))).\
    click()


def get_question_field(locator):
    txt= None
    for i in range(1,15):
        get_webdriver().refresh()

        WebDriverWait(get_webdriver(), 10).until(
        expected_conditions.presence_of_element_located((By.ID,"questions-tab"))).\
        click()

        el = WebDriverWait(get_webdriver(), 10).until(
        expected_conditions.presence_of_element_located((By.XPATH, locator)))
        txt = el.text
        if txt is not None:
            break
    return txt

def  wait_feature(d):
    for i in range(1,15):
        get_webdriver().refresh()

        WebDriverWait(get_webdriver(), 10).until(
        expected_conditions.visibility_of_element_located((By.ID,"features-tab"))).\
        click()    

        try:
            WebDriverWait(get_webdriver(), 10).until(
            expected_conditions.visibility_of_element_located((By.XPATH,"//div[contains(@id,'_Title')][contains(.,'"+d+"')]")))
            break
        except:
            pass

def kill_toaster():
    drv = get_webdriver()

    try:
        WebDriverWait(drv, 0.1).until(
            expected_conditions.visibility_of_element_located((By.ID, "toast-container")))

        toast_close_button = WebDriverWait(drv, 0.1).until(
            expected_conditions.visibility_of_element_located((By.CLASS_NAME, "toast-close-button")))

        toast_close_button.click()

        WebDriverWait(drv, 0.1).until(
            expected_conditions.invisibility_of_element_located((By.ID, "toast-container")))
    except:
        pass