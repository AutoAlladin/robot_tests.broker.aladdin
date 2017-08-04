*** Settings ***
Library           String
Library           Collections
Library           Selenium2Library
Resource          ../../op_robot_tests/tests_files/keywords.robot
Resource          ../../op_robot_tests/tests_files/resource.robot
Resource          Locators.robot
Library           DateTime
Library           conv_timeDate.py
Resource          aladdin.robot

*** Variables ***
${enid}           ${0}
${locator_necTitle}    id=featureTitle_
${dkkp_id}        ${EMPTY}

*** Keywords ***
Переговорная мультилотовая процедура
    [Arguments]    ${tender_data}
    Run Keyword If    ${log_enabled}    Log To Console    Start negotiation
    Full Click    ${locator_button_create}
    Full Click    ${locator_create_negotiation}
    Wait Until Page Contains Element    ${locator_tenderTitle}
    Info Negotiate    ${tender_data}
    ${trtte}=    Get From Dictionary    ${tender_data}    data
    ${ttt}=    Get From Dictionary    ${trtte}    items
    ${item}=    Get From List    ${ttt}    0
    Add item negotiate    ${item}    00    0
    ${item}=    Get From List    ${ttt}    1
    Add item negotiate    ${item}    01    0
    Execute Javascript    window.scroll(-1000, -1000)
    Full Click    ${locator_finish_edit}
    ${tender_UID}=    Publish tender/negotiation
    Run Keyword If    ${log_enabled}    Log To Console    End negotiation
    [Return]    ${tender_UID}

Открытые торги с публикацией на укр
    [Arguments]    ${tender}
    Full Click    ${locator_button_create}
    Full Click    //a[@href='/Purchase/Create/AboveThresholdUA']
    Info OpenUA    ${tender}
    Full Click    id=next_step
    Add Lot    1    ${tender.data.lots[0]}
    Full Click    id=next_step
    ${items}=    Get From Dictionary    ${tender.data}    items
    ${item}=    Get From List    ${items}    0
    Add Item    ${item}    10    1
    Full Click    id=next_step
    Add Feature    ${tender.data.features[1]}    0    0
    Add Feature    ${tender.data.features[0]}    1    0
    Add Feature    ${tender.data.features[2]}    1    0
    Full Click    id=movePurchaseView
    Run Keyword And Return    Publish tender

Открытые торги с публикацией на англ
    [Arguments]    ${tender}
    Full Click    ${locator_button_create}
    Full Click    id=url_create_purchase_3
    Info OpenEng    ${tender}
    ${ttt}=    Get From Dictionary    ${tender.data}    items
    ${item}=    Set Variable    ${ttt[0]}
    Add Item    ${item}    10    1
    Full Click    id=next_step
    Add Feature    ${tender.data.features[1]}    0    0
    Add Feature    ${tender.data.features[0]}    1    0
    Add Feature    ${tender.data.features[2]}    1    0
    Execute Javascript    window.scroll(-1000, -1000)
    Full Click    id=movePurchaseView
    Run Keyword And Return    Publish tender

Допороговый однопредметный тендер
    [Arguments]    ${tender_data}
    Full Click    ${locator_button_create}
    Full Click    url_create_purchase_1
    Wait Until Page Contains Element    ${locator_tenderTitle}
    Info Below    ${tender_data}
    Run Keyword If    ${NUMBER_OF_LOTS}==1    Full Click    next_step
    Run Keyword If    ${NUMBER_OF_LOTS}==1    Add Lot    1    ${tender_data.data.lots[0]}
    Run Keyword If    ${NUMBER_OF_LOTS}==1    Full Click    next_step
    ${ttt}=    Get From Dictionary    ${tender_data.data}    items
    ${item}=    Get From List    ${ttt}    0
    Run Keyword If    ${NUMBER_OF_LOTS}==1    Add Item    ${item}    10    1
    Run Keyword If    ${NUMBER_OF_LOTS}==0    Add Item    ${item}    00    0
    Full Click    id=movePurchaseView
    ${tender_UID}=    Publish tender
    [Return]    ${tender_UID}

Add Item
    [Arguments]    ${item}    ${d}    ${d_lot}
    #Клик доб позицию
    Full Click    ${locator_add_item_button}${d_lot}
    Full Click    ${locator_item_description}${d}
    #Название предмета закупки
    Input Text    ${locator_item_description}${d}    ${item.description}
    Run Keyword And Ignore Error    Execute Javascript    angular.element(document.getElementById('divProcurementSubjectControllerEdit')).scope().procurementSubject.guid='${item.id}'
    #Количество товара
    Wait Until Element Is Enabled    ${locator_Quantity}${d}
    Input Text    ${locator_Quantity}${d}    ${item.quantity}
    #Выбор ед измерения
    Wait Until Element Is Enabled    ${locator_code}${d}
    Select From List By Value    ${locator_code}${d}    ${item.unit.code}
    ${name}=    Get From Dictionary    ${item.unit}    name
    #Выбор ДК
    Full Click    ${locator_button_add_cpv}
    Wait Until Element Is Visible    ${locator_cpv_search}    30
    Press Key    ${locator_cpv_search}    ${item.classification.id}
    Wait Until Element Is Enabled    //*[@id='tree']//li[@aria-selected="true"]    30
    Full Click    ${locator_add_classfier}
    ${is_dkpp}=    Run Keyword And Ignore Error    Dictionary Should Contain Key    ${item}    additionalClassifications
    Set Suite Variable    ${dkkp_id}    000
    Run Keyword If    '${is_dkpp[0]}'=='PASS'    Get OtherDK    ${item}
    Set DKKP
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    xpath=//div[@class="modal-backdrop fade"]    10
    #Срок поставки (начальная дата)
    ${date_time}=    dt    ${item.deliveryDate.startDate}
    Fill Date    ${locator_date_delivery_start}${d}    ${date_time}
    Click Element    ${locator_date_delivery_start}${d}
    Click Element    ${locator_Quantity}${d}
    #Срок поставки (конечная дата)
    ${date_time}=    dt    ${item.deliveryDate.endDate}
    Fill Date    ${locator_date_delivery_end}${d}    ${date_time}
    Click Element    ${locator_date_delivery_end}${d}
    Click Element    ${locator_Quantity}${d}
    Run Keyword And Ignore Error    Full Click    xpath=//md-switch[@id='is_delivary_${d}']/div[2]/span
    #Выбор страны
    Select From List By Label    xpath=.//*[@id='select_countries${d}']['Україна']    ${item.deliveryAddress.countryName}
    Press Key    ${locator_postal_code}${d}    ${item.deliveryAddress.postalCode}
    aniwait
    Wait Until Element Is Enabled    id=select_regions${d}
    Set Region    ${item.deliveryAddress.region}    ${d}
    Press Key    ${locator_street}${d}    ${item.deliveryAddress.streetAddress}
    Press Key    ${locator_locality}${d}    ${item.deliveryAddress.locality}
    #Koordinate
    ${deliveryLocation_latitude}    Convert To String    ${item.deliveryLocation.latitude}
    ${deliveryLocation_latitude}    String.Replace String    ${deliveryLocation_latitude}    decimal    string
    Press Key    ${locator_deliveryLocation_latitude}${d}    ${deliveryLocation_latitude}
    ${deliveryLocation_longitude}=    Convert To String    ${item.deliveryLocation.longitude}
    ${deliveryLocation_longitude}=    String.Replace String    ${deliveryLocation_longitude}    decimal    string
    Press Key    ${locator_deliveryLocation_longitude}${d}    ${deliveryLocation_longitude}
    Run Keyword If    '${MODE}'=='openeu'    Add Item Eng    ${item}    ${d}
    #Клик кнопку "Створити"
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    xpath=.//div[@class='page-loader animated fadeIn']    5
    Wait Until Element Is Enabled    ${locator_button_create_item}${d}
    Full Click    ${locator_button_create_item}${d}
    Log To Console    finish item ${d}

Info Below
    [Arguments]    ${tender_data}
    Comment    Execute Javascript    angular.element(document.getElementById('purchaseAccelerator')).scope().purchase.accelerator = 10000
    #Ввод названия тендера
    Input Text    ${locator_tenderTitle}    ${tender_data.data.title}
    #Ввод описания
    Input Text    ${locator_description}    ${tender_data.data.description}
    #Выбор НДС
    ${PDV}=    Get From Dictionary    ${tender_data.data.value}    valueAddedTaxIncluded
    Run Keyword If    '${PDV}'=='True'    Click Element    ${locator_pdv}
    #Валюта
    Full Click    ${locator_currency}
    Select From List By Label    ${locator_currency}    ${tender_data.data.value.currency}
    Run Keyword If    ${NUMBER_OF_LOTS}<1    Set Tender Budget    ${tender_data}
    Run Keyword If    ${NUMBER_OF_LOTS}>0    Full Click    xpath=.//*[@id='is_multilot']/div[1]/div[2]
    #Период уточнений нач дата
    ${date_time_enq_st}=    dt    ${tender_data.data.enquiryPeriod.startDate}
    #Период уточнений кон дата
    ${date_time_enq_end}=    dt    ${tender_data.data.enquiryPeriod.endDate}
    #Период приема предложений (нач дата)
    ${date_time_ten_st}=    dt    ${tender_data.data.tenderPeriod.startDate}
    #Период приема предложений (кон дата)
    ${date_time_ten_end}=    dt    ${tender_data.data.tenderPeriod.endDate}
    Fill Date    ${locator_discussionDate_start}    ${date_time_enq_st}
    Fill Date    ${locator_discussionDate_end}    ${date_time_enq_end}
    Fill Date    ${locator_bidDate_start}    ${date_time_ten_st}
    Fill Date    ${locator_bidDate_end}    ${date_time_ten_end}
    Full Click    id=createOrUpdatePurchase
    Full Click    ${locator_button_next_step}

Info Negotiate
    [Arguments]    ${tender_data}
    Run Keyword If    ${log_enabled}    Log To Console    start info negotiation
    #Ввод названия закупки
    ${title}=    Get From Dictionary    ${tender_data.data}    title
    Press Key    ${locator_tenderTitle}    ${title}
    Run Keyword If    ${log_enabled}    Log To Console    Ввод названия закупки ${title}
    #Примечания
    ${description}=    Get From Dictionary    ${tender_data.data}    description
    Press Key    ${locator_description}    ${description}
    Run Keyword If    ${log_enabled}    Log To Console    Примечания ${description}
    #Условие применения переговорной процедуры
    ${select_directory_causes}=    Get From Dictionary    ${tender_data.data}    cause
    Full Click    id=select_directory_causes
    Log To Console    $("li[value='${tender_data.data.cause}']").trigger("click")
    Execute Javascript    $("li[value=\'${tender_data.data.cause}\']").trigger("click")
    Comment    Click Element    xpath=html/body
    Run Keyword If    ${log_enabled}    Log To Console    Условие применения переговорной процедуры ${select_directory_causes}
    #Обоснование
    ${cause_description}=    Get From Dictionary    ${tender_data.data}    causeDescription
    Press Key    ${locator_cause_description}    ${cause_description}
    Run Keyword If    ${log_enabled}    Log To Console    Обоснование \ ${cause_description}
    #Выбор НДС
    ${PDV}=    Get From Dictionary    ${tender_data.data.value}    valueAddedTaxIncluded
    Click Element    ${locator_pdv}
    Run Keyword If    ${log_enabled}    Log To Console    Выбор НДС ${PDV}
    #Валюта
    Wait Until Element Is Enabled    id=select_currencies    15
    ${currency}=    Get From Dictionary    ${tender_data.data.value}    currency
    Select From List By Label    id=select_currencies    ${currency}
    Press Key    id=select_currencies    ${currency}
    Full Click    id=select_currencies
    Run Keyword If    ${log_enabled}    Log To Console    Валюта ${currency}
    #Стоимость закупки
    ${budget}=    Get From Dictionary    ${tender_data.data.value}    amount
    ${text}=    Convert Float To String    ${budget}
    ${text}=    String.Replace String    ${text}    .    ,
    Press Key    ${locator_budget}    ${text}
    Run Keyword If    ${log_enabled}    Log To Console    Стоимость закупки ${text}
    Full Click    ${locator_next_step}
    Run Keyword If    ${log_enabled}    Log To Console    end info negotiation
    Execute Javascript    angular.element(document.getElementById('purchaseAccelerator')).scope().purchase.accelerator = 10000
    #xpath=.//li[@value="${tender_data.data.cause}"]

Login
    [Arguments]    ${user}
    Click Element    ${locator_cabinetEnter}
    Click Element    ${locator_enter}
    Wait Until Page Contains Element    Email    40
    Input Text    Email    ${user.login}
    Input Text    ${locator_passwordField}    ${user.password}
    Click Element    ${locator_loginButton}

Load document
    [Arguments]    ${filepath}    ${to}    ${to_name}
    Full Click    id=documents-tab
    Full Click    id=upload_document
    Wait Until Element Is Visible    id=categorySelect
    Comment    Execute Javascript    $("md-tabs-wrapper").css({"margin-top":"300px"})
    ${status}=    Run Keyword And Ignore Error    Select From List By Index    id=categorySelect    1
    Full Click    id=documentOfSelect
    Select From List By Value    id=documentOfSelect    ${to}
    Run Keyword If    '${to}'=='Lot'    Select Doc For Lot    ${to_name}
    Wait Until Page Contains Element    id=button_attach_document    60
    Wait Until Element Is Enabled    id=button_attach_document    60
    Choose File    id=fileInput    ${filepath}
    Full Click    id=save_file

Search tender
    [Arguments]    ${username}    ${tender_uaid}
    Comment    ${url}=    Fetch From Left    ${USERS.users['${username}'].homepage}
    Load Tender    ${apiUrl}/api/sync/purchase/tenderID/tenderID=${tender_uaid}
    Execute Javascript    var model=angular.element(document.getElementById('findbykeywords')).scope(); model.autotestignoretestmode=true;
    Wait Until Page Contains Element    ${locator_search_type}
    Wait Until Element Is Visible    ${locator_search_type}
    Select From List By Value    ${locator_search_type}    1    #По Id
    Wait Until Page Contains Element    ${locator_input_search}
    Wait Until Element Is Enabled    ${locator_input_search}
    Input Text    ${locator_input_search}    ${tender_uaid}
    Execute Javascript    window.scroll(0,-1000)
    aniwait
    Full Click    id=butSimpleSearch
    Wait Until Page Contains Element    xpath=//span[@class="hidden"][text()="${tender_uaid}"]/../a    50
    aniwait
    ${msg}=    Run Keyword And Ignore Error    Click Element    xpath=//span[@class="hidden"][text()="${tender_uaid}"]/../a
    Run Keyword If    '${msg[0]}'=='FAIL'    Capture Page Screenshot    fail_click_link.png

Info OpenUA
    [Arguments]    ${tender}
    #Ввод названия закупки
    ${status}=    Run Keyword And Ignore Error    Execute Javascript    $
    Run Keyword If    '${status[0]}'=='FAIL'    sleep    5
    Wait Until Page Contains Element    ${locator_tenderTitle}
    ${descr}=    Get From Dictionary    ${tender.data}    title
    Input Text    ${locator_tenderTitle}    ${descr}
    Input Text    id=description    ${tender.data.description}
    #Выбор НДС
    ${PDV}=    Get From Dictionary    ${tender.data.value}    valueAddedTaxIncluded
    Run Keyword If    '${PDV}'=='True'    Click Element    ${locator_pdv}
    #Валюта
    Full Click    select_currencies
    ${currency}=    Get From Dictionary    ${tender.data.value}    currency
    Select From List By Label    select_currencies    ${currency}
    Click Element    select_currencies
    Run Keyword If    ${NUMBER_OF_LOTS}<1    Set Tender Budget    ${tender}
    Run Keyword If    ${NUMBER_OF_LOTS}>0    Full Click    xpath=.//*[@id='is_multilot']/div[1]/div[2]
    #Период приема предложений (кон дата)
    ${date_time_ten_end}=    dt    ${tender.data.tenderPeriod.endDate}
    Fill Date    ${locator_bidDate_end}    ${date_time_ten_end}
    Full Click    ${locator_bidDate_end}
    Full Click    id=createOrUpdatePurchase

Add item negotiate
    [Arguments]    ${item}    ${q}    ${w}
    Run Keyword If    ${log_enabled}    Log To Console    start add item negotiation
    #Клик доб позицию
    sleep    3
    Full Click    ${locator_add_item_button}${w}
    Wait Until Element Is Enabled    ${locator_item_description}${q}
    Run Keyword If    ${log_enabled}    Log To Console    Click add item
    #Название предмета закупки
    ${add_classif}=    Get From Dictionary    ${item}    description
    Press Key    ${locator_item_description}${q}    ${add_classif}
    Run Keyword If    ${log_enabled}    Log To Console    Название предмета закупки ${add_classif}
    #Количество товара
    ${editItemQuant}=    Get From Dictionary    ${item}    quantity
    Wait Until Element Is Enabled    ${locator_Quantity}${q}
    Input Text    ${locator_Quantity}${q}    ${editItemQuant}
    Run Keyword If    ${log_enabled}    Log To Console    Количество товара ${editItemQuant}
    #Выбор ед измерения
    Wait Until Element Is Enabled    ${locator_code}${q}
    ${code}=    Get From Dictionary    ${item.unit}    code
    Select From List By Value    ${locator_code}${q}    ${code}
    ${name}=    Get From Dictionary    ${item.unit}    name
    Run Keyword If    ${log_enabled}    Log To Console    Выбор ед измерения ${code} ${name}
    #Выбор ДК
    ${status}=    Run Keyword And Ignore Error    Click Button    ${locator_button_add_cpv}
    Comment    Run Keyword If    '${status[0]}'=='FAIL'    sleep    5000
    Sleep    5
    Wait Until Element Is Enabled    ${locator_cpv_search}    30
    ${cpv}=    Get From Dictionary    ${item.classification}    id
    Press Key    ${locator_cpv_search}    ${cpv}
    Wait Until Element Is Enabled    //*[@id='tree']//li[@aria-selected="true"]    30
    Full Click    ${locator_add_classfier}
    Run Keyword If    ${log_enabled}    Log To Console    Выбор ДК ${cpv}
    #Выбор др ДК
    sleep    1
    ${is_dkpp}=    Run Keyword And Ignore Error    Dictionary Should Contain Key    ${item}    additionalClassifications
    Log To Console    is DKKP - \ ${is_dkpp[0]} \ - \ ${is_dkpp[1]}
    Log To Console    cpv ${cpv}
    Set Suite Variable    ${dkkp_id}    000
    Run Keyword If    '${is_dkpp[0]}'=='PASS'    Get OtherDK    ${item}
    Set DKKP
    Run Keyword If    ${log_enabled}    Log To Console    Выбор др ДК ${is_dkpp}
    #Срок поставки (начальная дата)
    sleep    10
    ${delivery_Date_start}=    Get From Dictionary    ${item.deliveryDate}    startDate
    ${date_time}=    dt    ${delivery_Date_start}
    Fill Date    ${locator_date_delivery_start}${q}    ${date_time}
    Run Keyword If    ${log_enabled}    Log To Console    Срок поставки (начальная дата) ${date_time}
    #Срок поставки (конечная дата)
    ${delivery_Date}=    Get From Dictionary    ${item.deliveryDate}    endDate
    ${date_time}=    dt    ${delivery_Date}
    Fill Date    ${locator_date_delivery_end}${q}    ${date_time}
    Run Keyword If    ${log_enabled}    Log To Console    Срок поставки (конечная дата) ${date_time}
    #Выбор страны
    ${country}=    Get From Dictionary    ${item.deliveryAddress}    countryName
    Select From List By Label    ${locator_country_id}${q}    ${country}
    Run Keyword If    ${log_enabled}    Log To Console    Выбор страны ${country}
    #Выбор региона
    sleep    5
    ${region}=    Get From Dictionary    ${item.deliveryAddress}    region
    Set Region    ${region}    ${q}
    Comment    Execute Javascript    var autotestmodel=angular.element(document.getElementById('select_regions00')).scope(); autotestmodel.procurementSubject.procurementSubject.region=autotestmodel.procurementSubject.procurementSubject.region; autotestmodel.procurementSubject.procurementSubject.region={id:0,name:'${region}',initName:'${region}'};
    Comment    Comment    Select From List By Label    ${locator_SelectRegion}${q}    ${region}
    Run Keyword If    ${log_enabled}    Log To Console    Выбор региона ${region}
    #Индекс
    ${post_code}=    Get From Dictionary    ${item.deliveryAddress}    postalCode
    Press Key    ${locator_postal_code}${q}    ${post_code}
    Run Keyword If    ${log_enabled}    Log To Console    Индекс ${post_code}
    ${locality}=    Get From Dictionary    ${item.deliveryAddress}    locality
    Press Key    ${locator_locality}${q}    ${locality}
    Run Keyword If    ${log_enabled}    Log To Console    Насел пункт ${locality}
    ${street}=    Get From Dictionary    ${item.deliveryAddress}    streetAddress
    Press Key    ${locator_street}${q}    ${street}
    Run Keyword If    ${log_enabled}    Log To Console    Адрес ${street}
    sleep    3
    Comment    Click Element    ${locator_check_gps}${q}
    ${deliveryLocation_latitude}=    Get From Dictionary    ${item.deliveryLocation}    latitude
    ${deliveryLocation_latitude}    Convert Float To String    ${deliveryLocation_latitude}
    ${deliveryLocation_latitude}    String.Replace String    ${deliveryLocation_latitude}    decimal    string
    Press Key    ${locator_deliveryLocation_latitude}${q}    ${deliveryLocation_latitude}
    Run Keyword If    ${log_enabled}    Log To Console    Широта ${deliveryLocation_latitude}
    ${deliveryLocation_longitude}=    Get From Dictionary    ${item.deliveryLocation}    longitude
    ${deliveryLocation_longitude}=    Convert Float To String    ${deliveryLocation_longitude}
    ${deliveryLocation_longitude}=    String.Replace String    ${deliveryLocation_longitude}    decimal    string
    Press Key    ${locator_deliveryLocation_longitude}${q}    ${deliveryLocation_longitude}
    Run Keyword If    ${log_enabled}    Log To Console    Долгота ${deliveryLocation_longitude}
    Execute Javascript    window.scroll(1000, 1000)
    sleep    2
    #Клик кнопку "Створити"
    Full Click    ${locator_button_create_item}${q}
    sleep    2
    Run Keyword If    ${log_enabled}    Log To Console    end add item negotiation

Publish tender
    Run Keyword And Ignore Error    Wait Until Element Is Visible    id=save_changes    5
    Run Keyword And Ignore Error    Click Button    id=save_changes
    ${id}=    Get Location
    Full Click    ${locator_publish_tender}
    Wait Until Page Contains Element    id=purchaseProzorroId    50
    Wait Until Element Is Visible    id=purchaseProzorroId    90
    aniwait
    ${tender_UID}=    Get Text    xpath=//span[@id='purchaseProzorroId']
    Log To Console    publish tender ${tender_UID}
    Return From Keyword    ${tender_UID}
    [Return]    ${tender_UID}

Add question
    [Arguments]    ${tender_data}
    Select From List By Value    ${locator_question_to}    0
    ${title}=    Get From Dictionary    ${tender_data.data}    title
    Press Key    ${locator_question_title}    ${title}
    ${description}=    Get From Dictionary    ${tender_data.data}    description
    Press Key    ${locator_description_question}    ${description}

Add Lot
    [Arguments]    ${d}    ${lot}
    Full Click    ${locator_multilot_new}
    Wait Until Page Contains Element    ${locator_multilot_title}${d}    30
    Wait Until Element Is Enabled    ${locator_multilot_title}${d}
    Input Text    ${locator_multilot_title}${d}    ${lot.title}
    Input Text    id=lotDescription_${d}    ${lot.description}
    Execute Javascript    angular.element(document.getElementById('divLotControllerEdit')).scope().lotPurchasePlan.guid='${lot.id}'
    ${budget}=    Get From Dictionary    ${lot.value}    amount
    ${text}=    Convert Float To String    ${budget}
    ${text}=    String.Replace String    ${text}    .    ,
    Input Text    id=lotBudget_${d}    ${text}
    ${step}=    Get From Dictionary    ${lot.minimalStep}    amount
    ${text}=    Convert Float To String    ${step}
    ${text}=    String.Replace String    ${text}    .    ,
    Press Key    id=lotMinStep_${d}    ${text}
    Press Key    id=lotMinStep_${d}    00
    #Input Text    id=lotGuarantee_${d}
    Full Click    xpath=.//*[@id='updateOrCreateLot_1']//button[@class="btn btn-success"]
    Log To Console    finish lot ${d}

Fill Date
    [Arguments]    ${id}    ${value}
    ${id}    Replace String    ${id}    id=    ${EMPTY}
    ${ddd}=    Set Variable    SetDateTimePickerValue(\'${id}\',\'${value}\');
    sleep    2
    Execute Javascript    ${ddd}

Set Tender Budget
    [Arguments]    ${tender}
    #Ввод бюджета
    ${budget}=    Get From Dictionary    ${tender.data.value}    amount
    ${text}=    Convert Float To String    ${budget}
    ${text}=    String.Replace String    ${text}    .    ,
    Press Key    ${locator_budget}    ${text}
    #Ввод мин шага
    ${min_step}=    Get From Dictionary    ${tender.data.minimalStep}    amount
    ${text_ms}=    Convert Float To String    ${min_step}
    ${text_ms}=    String.Replace String    ${text_ms}    .    ,
    Press Key    ${locator_min_step}    ${text_ms}

Info OpenEng
    [Arguments]    ${tender}
    Log To Console    start openEng info
    #Ввод названия закупки
    Wait Until Page Contains Element    ${locator_tenderTitle}
    Input Text    ${locator_tenderTitle}    ${tender.data.title}
    Input Text    ${locator_titleEng}    ${tender.data.title_en}
    Input Text    id=description    ${tender.data.description}
    #Выбор НДС
    ${PDV}=    Get From Dictionary    ${tender.data.value}    valueAddedTaxIncluded
    Run Keyword If    '${PDV}'=='True'    Click Element    ${locator_pdv}
    #Выбор многолотовости
    Full Click    ${locator_multilot_enabler}
    #Валюта
    Full Click    ${locator_currency}
    ${currency}=    Get From Dictionary    ${tender.data.value}    currency
    Select From List By Label    ${locator_currency}    ${tender.data.value.currency}
    Press Key    ${locator_currency}    ${currency}
    Full Click    ${locator_currency}
    #Период приема предложений (кон дата)
    ${date_time_ten_end}=    dt    ${tender.data.tenderPeriod.endDate}
    Fill Date    ${locator_bidDate_end}    ${date_time_ten_end}
    Full Click    id=createOrUpdatePurchase
    Full Click    ${locator_next_step}
    Log To Console    finish openEng info
    #Добавление лота
    Full Click    ${locator_multilot_new}
    ${w}=    Set Variable    1
    ${lot}=    Get From Dictionary    ${tender.data}    lots
    ${lot}=    Get From List    ${lot}    0
    Log To Console    ${locator_multilot_title}${w}
    Wait Until Page Contains Element    ${locator_multilot_title}${w}
    Wait Until Element Is Enabled    ${locator_multilot_title}${w}
    Input Text    ${locator_multilot_title}${w}    ${lot.title}
    Input Text    ${locator_lotTitleEng}${w}    ${lot.title_en}
    Input Text    id=lotDescription_${w}    ${lot.description}
    ${budget}=    Get From Dictionary    ${lot.value}    amount
    ${text}=    Convert Float To String    ${budget}
    ${text}=    String.Replace String    ${text}    .    ,
    Press Key    id=lotBudget_${w}    ${text}
    Comment    Convert Float To String    ${lot.value.amount}
    Comment    Input Text    id=lotBudget_${w}    ${lot.value.amount}
    Comment    Input Text    id=lotMinStep_${w}    ${lot.minimalStep.amount}
    Comment    Input Text    id=lotMinStep_${w}    00
    ${minStep}=    Get From Dictionary    ${lot.minimalStep}    amount
    ${text_ms}=    Convert Float To String    ${lot.minimalStep.amount}
    ${text_ms}=    String.Replace String    ${text_ms}    .    ,
    Press Key    id=lotMinStep_${w}    ${text_ms}
    Comment    Input Text    id=lotMinStep_${w}    00
    #Input Text    id=lotGuarantee_${w}
    Full Click    xpath=.//*[@id='divLotControllerEdit']/div/div/div/div[9]/div/button[1]
    Comment    Full Click    xpath=.//*[@id='updateOrCreateLot_1']//a[@ng-click="editLot(lotPurchasePlan)"]
    Run Keyword And Ignore Error    Wait Until Page Contains Element    ${locator_toast_container}
    Run Keyword And Ignore Error    Click Button    ${locator_toast_close}
    Wait Until Page Contains Element    xpath=.//*[@id='updateOrCreateLot_1']//a[@ng-click="editLot(lotPurchasePlan)"]
    Log To Console    finish lot ${w}
    #нажатие след.шаг
    Full Click    ${locator_next_step}

Add Item Eng
    [Arguments]    ${item}    ${d}
    #Название предмета закупки
    Wait Until Element Is Enabled    ${locator_item_descriptionEng}${d}
    ${add_classifEng}=    Get From Dictionary    ${item}    description_en
    Log To Console    ${add_classifEng} \ \ \ \ \ \ ${locator_item_descriptionEng}${d}
    Input Text    ${locator_item_descriptionEng}${d}    ${add_classifEng}

Add Feature
    [Arguments]    ${fi}    ${lid}    ${pid}
    aniwait
    sleep    3
    Full Click    id=add_features${lid}
    Wait Until Element Is Enabled    id=featureTitle_${lid}_${pid}
    #Param0
    Input Text    id=featureTitle_${lid}_${pid}    ${fi.title}
    Run Keyword If    '${MODE}'=='openeu'    Input Text    id=featureTitle_En_${lid}_${pid}    ${fi.title_en}
    Input Text    id=featureDescription_${lid}_${pid}    ${fi.description}
    # Position nec
    ${status}=    Run Keyword And Ignore Error    Dictionary Should Contain Key    ${fi}    item_id
    Run Keyword If    '${fi.featureOf}'=='item'    Run Keyword If    '${status[0]}'=='FAIL'    Select Item Param    ${fi.relatedItem}
    Run Keyword If    '${fi.featureOf}'=='item'    Run Keyword If    '${status[0]}'=='PASS'    Select Item Param Label    ${fi.item_id}
    #Enum_0_1
    Set Suite Variable    ${enid}    ${0}
    ${enums}=    Get From Dictionary    ${fi}    enum
    : FOR    ${enum}    IN    @{enums}
    \    ${val}=    Evaluate    int(${enum.value}*${100})
    \    Run Keyword If    ${val}>0    Add Enum    ${enum}    ${lid}_${pid}
    \    Run Keyword If    ${val}==0    Input Text    id=featureEnumTitle_${lid}_${pid}_0    ${enum.title}
    \    Run Keyword If    (${val}==0)&('${MODE}'=='openeu')    Input Text    id=featureEnumTitleEn_${lid}_${pid}_0    flowers
    Wait Until Element Is Enabled    id=updateFeature_${lid}_${pid}
    Full Click    id=updateFeature_${lid}_${pid}

Set DKKP
    Log To Console    ${dkkp_id}
    #Выбор др ДК
    sleep    1
    Wait Until Element Is Enabled    ${locator_button_add_dkpp}
    Click Button    ${locator_button_add_dkpp}
    Wait Until Element Is Visible    ${locator_dkpp_search}
    Clear Element Text    ${locator_dkpp_search}
    Press Key    ${locator_dkpp_search}    ${dkkp_id}
    Wait Until Element Is Enabled    //*[@id='tree']//li[@aria-selected="true"]    30
    Wait Until Element Is Enabled    ${locator_add_classfier}
    Click Button    ${locator_add_classfier}

Add Enum
    [Arguments]    ${enum}    ${p}
    ${val}=    Evaluate    int(${enum.value}*${100})
    Full Click    xpath=//button[@ng-click="addFeatureEnum(lotPurchasePlan, features)"]
    ${enid_}=    Evaluate    ${enid}+${1}
    Set Suite Variable    ${enid}    ${enid_}
    ${end}=    Set Variable    ${p}_${enid}
    Comment    Log To Console    id=featureEnumValue_${end} - \ \ ${val}
    Wait Until Page Contains Element    id=featureEnumValue_${end}    15
    Comment    Run Keyword And Return If    '${MODE}'=='openeu'    Input Text    id=featureEnumTitle_En${end}    ${enum.title_en}
    Input Text    id=featureEnumValue_${end}    ${val}
    Input Text    id=featureEnumTitle_${end}    ${enum.title}
    Run Keyword And Return If    '${MODE}'=='openeu'    Input Text    id=featureEnumTitleEn_${end}    flowers

Sync
    [Arguments]    ${uaid}    ${api}
    Execute Javascript    $.get('${apiUrl}/api/sync/purchase/tenderID/tenderID=${uaid}');
    ${guid}=    Execute Javascript    return $.get('publish/SearchTenderById?tenderId=${uaid}&guid=ac8dd2f8-1039-4e27-8d98-3ef50a728ebf')
    Log To Console    $.get('${apiUrl}/api/sync/purchase/tenderID/tenderID=${uaid}');

Get OtherDK
    [Arguments]    ${item}
    ${dkpp}=    Get From List    ${item.additionalClassifications}    0
    ${dkpp_id_local}=    Get From Dictionary    ${dkpp}    id
    Log To Console    Other DK ${dkpp_id_local}
    Set Suite Variable    ${dkkp_id}    ${dkpp_id_local}

Publish tender/negotiation
    Run Keyword If    ${log_enabled}    Log To Console    start publish tender
    Log To Console    start publish tender
    aniwait
    Wait Until Page Contains Element    id=publishNegotiationAutoTest    90
    Wait Until Element Is Enabled    id=publishNegotiationAutoTest
    sleep    3
    Execute Javascript    $("#publishNegotiationAutoTest").click()
    ${url}=    Get Location
    Log To Console    ${url}
    sleep    5
    Comment    Wait Until Page Contains Element    id=purchaseProzorroId    50
    Comment    ${tender_UID}=    Execute Javascript    var model=angular.element(document.getElementById('purchse-controller')).scope(); return model.$$childHead.purchase.purchase.prozorroId
    Wait Until Element Is Visible    id=purchaseProzorroId    90
    ${tender_UID}=    Get Text    id=purchaseProzorroId
    ${tender_GUID}=    Get Text    id=purchaseGuid
    Log To Console    UID=${tender_UID}
    ${url}=    Get Location
    ${url}=    Fetch From Left    ${url}    :90
    Log To Console    ${url}
    Execute Javascript    $.get('${url}:92/api/sync/purchases/${tender_GUID}')
    Reload Page
    Log To Console    finish publish tender ${tender_UID}
    Return From Keyword    ${tender_UID}
    Run Keyword If    ${log_enabled}    Log To Console    end publish tender
    [Return]    ${tender_UID}

Select Item Param
    [Arguments]    ${relatedItem}
    Wait Until Page Contains Element    xpath=//label[@for='featureOf_1_0']
    Wait Until Element Is Visible    xpath=//label[@for='featureOf_1_0']
    Click Element    xpath=//label[@for='featureOf_1_0']
    Wait Until Page Contains Element    id=featureItem_1_0
    Wait Until Element Is Enabled    id=featureItem_1_0
    Select From List By Value    id=featureItem_1_0    string:${relatedItem}

Select Doc For Lot
    [Arguments]    ${arg}
    Full Click    xpath=//select[@name='DocumentOf']
    Wait Until Page Contains Element    id=documentOfLotSelect    30
    Wait Until Element Is Enabled    id=documentOfLotSelect    30
    ${arg}=    Get Text    xpath=//option[contains(@label,'${arg}')]
    Select From List By Label    id=documentOfLotSelect    ${arg}

Set Region
    [Arguments]    ${region}    ${item_no}
    Execute Javascript    var autotestmodel=angular.element(document.getElementById('select_regions${item_no}')).scope(); autotestmodel.regions.push({id:0,name:'${region}'}); autotestmodel.$apply(); autotestmodel; \ $("#select_regions${item_no} option[value='0']").attr("selected", "selected"); var autotestmodel=angular.element(document.getElementById('procurementSubject_description${item_no}')).scope(); autotestmodel.procurementSubject.region={}; \ autotestmodel.procurementSubject.region.id=0; autotestmodel.procurementSubject.region.name='${region}';

Select Item Param Label
    [Arguments]    ${relatedItem}
    Log To Console    ad item param \ ${relatedItem}
    Wait Until Page Contains Element    xpath=//label[@for='featureOf_1_0']
    Wait Until Element Is Visible    xpath=//label[@for='featureOf_1_0']
    Click Element    xpath=//label[@for='featureOf_1_0']
    Wait Until Page Contains Element    id=featureItem_1_0
    Wait Until Element Is Enabled    id=featureItem_1_0
    ${lb}=    Get Element Attribute    xpath=//select[@id='featureItem_1_0']/option[contains(@label,'${relatedItem}')]@label
    Log To Console    ${lb}
    Select From List By Label    id=featureItem_1_0    ${lb}

aniwait
    Run Keyword And Ignore Error    Wait For Condition    return $(".page-loader").css("display")=="none"    40

Full Click
    [Arguments]    ${lc}
    Wait Until Page Contains Element    ${lc}    40
    Wait Until Element Is Enabled    ${lc}    40
    Wait Until Element Is Visible    ${lc}    10
    aniwait
    Click Element    ${lc}

Add Bid Tender
    [Arguments]    ${amount}
    Wait Until Page Contains Element    id=bidAmount    60
    Wait Until Element Is Enabled    id=bidAmount
    ${text}=    Convert Float To String    ${amount}
    Input Text    id=bidAmount    ${text}
    Full Click    id=submitBid

Add Bid Lot
    [Arguments]    @{params}
    ${to_id}=    Set Variable    ${params[1]}
    Full Click    //a[contains(@id,'openLotForm')][contains(text(),'${to_id[0]}')]
    ${end}=    Get Element Attribute    xpath=//a[contains(@id,'openLotForm')][contains(text(),'${to_id[0]}')]@id
    ${end}=    Fetch From Right    ${end}    openLotForm
    Wait Until Page Contains Element    id=lotAmount${end}
    ${amount}=    Convert Float To String    ${params[0].data.lotValues[0].value.amount}
    Input Text    id=lotAmount${end}    ${amount}
    Run Keyword And Ignore Error    Run Keyword If    ${params[0].data.selfEligible}==${True}    Click Element    xpath=//label[@for='isSelfEligible${end}']
    Run Keyword And Ignore Error    Run Keyword If    ${params[0].data.selfQualified}==${True}    Click Element    xpath=//label[@for='isSelfQualified${end}']
    @{fiis}=    Set Variable    ${params[2]}
    : FOR    ${fi}    IN    @{fiis}
    \    ${code}=    Get Text    xpath=//h6[contains(text(),'${fi}')]/../h6[2]
    \    ${value}=    Get Param By Id    ${code}    ${params[0].data.parameters}
    \    Select From List By Value    xpath=//h6[contains(text(),'${fi}')]/../select    string:${value}
    Comment    Input Text    id=lotSubInfo${end}    text
    Full Click    id=lotSubmit${end}

Get Param By Id
    [Arguments]    ${m}    ${p}
    : FOR    ${pp}    IN    @{p}
    \    Return From Keyword If    '${pp['code']}'=='${m}'    ${pp['value']}

Get Info Award
    [Arguments]    ${arguments[0]}    ${arguments[1]}
    #***Award***
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].status'    Get Field Text    id=winner_status
    #***Award Budget***
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].value.amount'    Get Field Amount    id=procuringParticipantsAmount_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].value.currency'    Get Field Text    id=procuringParticipantsCurrency_0_0
    ${awardIsVAT}=    Execute Javascript    return $('#procuringParticipantsIsVAT_0_0').text();
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].value.valueAddedTaxIncluded'    Convert To Boolean    ${awardIsVAT}
    #***Award Suppliers(identifier/contactPoint/address)***
    Run Keyword If    '${role}'=='viewer'    Full Click    id=participants-tab
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].name'    Get Field Text    id=procuringParticipantsIdentifierLegalName_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].identifier.id'    Get Field Text    id=procuringParticipantsIdentifierCode_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].identifier.scheme'    Get Field Text    id=procuringParticipantsIdentifierScheme_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].identifier.legalName'    Get Field Text    id=procuringParticipantsIdentifierLegalName_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].contactPoint.telephone'    Get Field Text    id=procuringParticipantsContactPointPhone_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].contactPoint.name'    Get Field Text    id=procuringParticipantsContactPointName_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].contactPoint.email'    Get Field Text    id=procuringParticipantsContactPointEmail_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].address.countryName'    Get Field Text    id=procuringParticipantsAddressCountryName_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].address.region'    Get Field Text    id=procuringParticipantsAddressRegion_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].address.locality'    Get Field Text    id=procuringParticipantsAddressLocality_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].address.postalCode'    Get Field Text    id=procuringParticipantsAddressZipCode_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].suppliers[0].address.streetAddress'    Get Field Text    id=procuringParticipantsAddressStreet_0_0
    #***Award Period***
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].complaintPeriod.endDate'    Get Field Date    xpath=.//*[contains(@id,'ContractComplaintPeriodEnd_')]
    #***Documents***
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].documents[0].title'    Get Field Doc for paticipant    xpath=.//*[@class="ng-binding"][contains(@id,'awardsdoc')]
    #***Contracts***
    Sleep    60
    Reload Page
    Comment    Full Click    id=results-tab
    Wait Until Element Is Visible    id=tab-content-3
    Sleep    10
    Run Keyword And Return If    '${arguments[1]}'=='contracts[0].status'    Execute Javascript    return $('#resultPurchseContractStatus_0').text();

Get Info Contract
    [Arguments]    ${arguments[0]}    ${arguments[1]}
    Sleep    60
    Reload Page
    Run Keyword And Return If    '${role}'=='viewer'    Full Click    id=results-tab
    Run Keyword And Return If    '${role}'=='viewer'    Wait Until Element Is Visible    id=tab-content-3
    Sleep    10
    Run Keyword And Return If    '${role}'=='viewer'    '${arguments[1]}'=='contracts[0].status'    Execute Javascript    return $('#resultPurchseContractStatus_0').text();

Get Info Contract (owner)
    [Arguments]    @{arguments}
    sleep    30
    Run Keyword If    '${role}'=='tender_owner'    Full Click    id=processing-tab
    Run Keyword And Return If    '${arguments[1]}'=='contracts[0].status'    Get Field Text    xpath=.//*[contains(@id,'ContractComplaintPeriodEnd_')]
    Run Keyword And Return If    '${arguments[1]}'=='contracts[0].status'    Execute Javascript    return $('#contractStatusName_').text();
