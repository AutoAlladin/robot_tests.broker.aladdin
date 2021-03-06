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
${feature_suffix}    ${0}
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
    ${tnd_data}=    Get From Dictionary    ${tender_data}    data
    ${items}=    Get From Dictionary    ${tnd_data}    items
    ${item}=    Get From List    ${items}    0
    Add item negotiate    ${item}    00    0    00
    ${item}=    Get From List    ${items}    1
    Add item negotiate    ${item}    00    0    01
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
    sleep    10
    Full Click    id=features-tab
    Add Feature    ${tender.data.features[1]}    0    0
    Add Feature    ${tender.data.features[0]}    1    0
    Add Feature    ${tender.data.features[2]}    1    0
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
    [Arguments]    ${item}    ${item_suffix}    ${d_lot}
    #Клик доб позицию
    Full Click    ${locator_add_item_button}${d_lot}
    Full Click    ${locator_item_description}${item_suffix}
    #Название предмета закупки
    Input Text    ${locator_item_description}${item_suffix}    ${item.description}
    Run Keyword And Ignore Error    Execute Javascript    angular.element(document.getElementById('divProcurementSubjectControllerEdit')).scope().procurementSubject.guid='${item.id}'
    #Количество товара
    Wait Until Element Is Enabled    ${locator_Quantity}${item_suffix}
    Input Text    ${locator_Quantity}${item_suffix}    ${item.quantity}
    #Выбор ед измерения
    Wait Until Element Is Enabled    ${locator_code}${item_suffix}
    Select From List By Value    ${locator_code}${item_suffix}    ${item.unit.code}
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
    ${date_time}=    get_aladdin_formated_date    ${item.deliveryDate.startDate}
    Fill Date    ${locator_date_delivery_start}${item_suffix}    ${date_time}
    #Срок поставки (конечная дата)
    ${date_time}=    get_aladdin_formated_date    ${item.deliveryDate.endDate}
    Fill Date    ${locator_date_delivery_end}${item_suffix}    ${date_time}
    Run Keyword And Ignore Error    Full Click    xpath=//md-switch[@id='is_delivary_${item_suffix}']/div[2]/span
    #Выбор страны
    Wait Until Element Is Visible    xpath=.//*[@id='select_countries${item_suffix}']
    Select From List By Label    xpath=.//*[@id='select_countries${item_suffix}']    ${item.deliveryAddress.countryName}
    Press Key    ${locator_postal_code}${item_suffix}    ${item.deliveryAddress.postalCode}
    aniwait
    Wait Until Element Is Enabled    id=select_regions${item_suffix}
    sleep    2
    Set Region    ${item.deliveryAddress.region}    ${item_suffix}    ${item_suffix}
    Press Key    ${locator_street}${item_suffix}    ${item.deliveryAddress.streetAddress}
    Press Key    ${locator_locality}${item_suffix}    ${item.deliveryAddress.locality}
    #Koordinate
    ${deliveryLocation_latitude}    Convert To String    ${item.deliveryLocation.latitude}
    ${deliveryLocation_latitude}    String.Replace String    ${deliveryLocation_latitude}    decimal    string
    Press Key    ${locator_deliveryLocation_latitude}${item_suffix}    ${deliveryLocation_latitude}
    ${deliveryLocation_longitude}=    Convert To String    ${item.deliveryLocation.longitude}
    ${deliveryLocation_longitude}=    String.Replace String    ${deliveryLocation_longitude}    decimal    string
    Press Key    ${locator_deliveryLocation_longitude}${item_suffix}    ${deliveryLocation_longitude}
    Run Keyword If    '${MODE}'=='openeu'    Add Item Eng    ${item}    ${item_suffix}
    #Клик кнопку "Створити"
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    xpath=.//div[@class='page-loader animated fadeIn']    5
    Wait Until Element Is Enabled    ${locator_button_create_item}${item_suffix}
    Full Click    ${locator_button_create_item}${item_suffix}
    Log To Console    finish item ${item_suffix}

Info Below
    [Arguments]    ${tender_data}
    #Ввод названия тендера
    Run Keyword And Ignore Error    Full Click    ${locator_tenderTitle}
    Input Text    ${locator_tenderTitle}    ${tender_data.data.title}
    Run Keyword If    '${tender_data.data.procurementMethodDetails}'=='quick, accelerator=100'    Execute Javascript    angular.element(document.getElementById('purchaseAccelerator')).scope().purchase.accelerator = 100
    Comment    Execute Javascript    angular.element(document.getElementById('purchaseAccelerator')).scope().purchase.accelerator = 100
    Run Keyword If    '${tender_data.data.procurementMethodDetails}'=='quick, accelerator=100'    Execute Javascript    var autotestmodel=angular.element(document.getElementById('titleOfTenderForEdit')).scope(); autotestmodel.purchase.modeFastForward=true;
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
    ${date_time_enq_st}=    get_aladdin_formated_date    ${tender_data.data.enquiryPeriod.startDate}
    #Период уточнений кон дата
    ${date_time_enq_end}=    get_aladdin_formated_date    ${tender_data.data.enquiryPeriod.endDate}
    #Период приема предложений (нач дата)
    ${date_time_ten_st}=    get_aladdin_formated_date    ${tender_data.data.tenderPeriod.startDate}
    #Период приема предложений (кон дата)
    ${date_time_ten_end}=    get_aladdin_formated_date    ${tender_data.data.tenderPeriod.endDate}
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
    Full Click    ${locator_tenderTitle}
    ${title}=    Get From Dictionary    ${tender_data.data}    title
    Press Key    ${locator_tenderTitle}    ${title}
    Run Keyword If    ${log_enabled}    Log To Console    Ввод названия закупки ${title}
    ${title_ru}=    Get From Dictionary    ${tender_data.data}    title_ru
    Execute Javascript    angular.element(document.getElementById('title_Ru')).scope().purchase.title_Ru='${title_ru}'
    ${title_en}=    Get From Dictionary    ${tender_data.data}    title_en
    Execute Javascript    angular.element(document.getElementById('title_En')).scope().purchase.title_En='${title_en}'
    #Примечания
    ${description}=    Get From Dictionary    ${tender_data.data}    description
    Press Key    ${locator_description}    ${description}
    Run Keyword If    ${log_enabled}    Log To Console    Примечания ${description}
    ${description_ru}=    Get From Dictionary    ${tender_data.data}    description_ru
    Execute Javascript    angular.element(document.getElementById('description_Ru')).scope().purchase.description_Ru='${description_ru}'
    ${description_en}=    Get From Dictionary    ${tender_data.data}    description_en
    Execute Javascript    angular.element(document.getElementById('description_En')).scope().purchase.description_En='${description_en}'
    #Условие применения переговорной процедуры
    ${select_directory_causes}=    Get From Dictionary    ${tender_data.data}    cause
    Full Click    id=select_directory_causes
    Log To Console    $("li[value='${tender_data.data.cause}']").trigger("click")
    Execute Javascript    $("li[value=\'${tender_data.data.cause}\']").trigger("click")
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
    Execute Javascript    angular.element(document.getElementById('purchaseAccelerator')).scope().purchase.accelerator = 8000

Login
    [Arguments]    ${user}
    Full Click    ${locator_cabinetEnter}
    Full Click    ${locator_enter}
    Wait Until Page Contains Element    id=Email    40
    sleep    2
    Press Key    id=Email    ${user.login}
    sleep    2
    Press Key    id=Password    ${user.password}
    sleep    2
    Wait Until Element Is Visible    ${locator_loginButton}    30
    Comment    Full Click    ${locator_loginButton}
    Execute Javascript    $('#submitLogin').click();

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
    Load Tender    ${apiUrl}/publish/SearchTenderById?guid=ac8dd2f8-1039-4e27-8d98-3ef50a728ebf&tenderId=${tender_uaid}
    Wait Until Page Contains Element    id=butSimpleSearch    40
    Wait Until Page Contains Element    ${locator_search_type}
    Wait Until Element Is Visible    ${locator_search_type}
    Select From List By Value    ${locator_search_type}    1    #По Id
    Wait Until Page Contains Element    ${locator_input_search}
    Wait Until Element Is Enabled    ${locator_input_search}
    Input Text    ${locator_input_search}    ${tender_uaid}
    aniwait
    Full Click    id=butSimpleSearch
    Full Click    id=butSimpleSearch
    Wait Until Page Contains Element    xpath=//span[text()="${tender_uaid}"]/../a    50
    sleep    5
    ${attributeHref}=    Get Element Attribute    //span[text()="${tender_uaid}"]/../a@href
    Go To    ${attributeHref}
    aniwait
    Run Keyword And Ignore Error    Wait Until Page Contains Element    purchaseProzorroId    40

Info OpenUA
    [Arguments]    ${tender}
    #Ввод названия закупки
    ${status}=    Run Keyword And Ignore Error    Execute Javascript    $
    Run Keyword If    '${status[0]}'=='FAIL'    sleep    5
    Full Click    ${locator_tenderTitle}
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
    ${date_time_ten_end}=    get_aladdin_formated_date    ${tender.data.tenderPeriod.endDate}
    Fill Date    ${locator_bidDate_end}    ${date_time_ten_end}
    Full Click    ${locator_bidDate_end}
    Full Click    id=createOrUpdatePurchase

Add item negotiate
    [Arguments]    ${item}    ${id_suffix}    ${lot_number}    ${id_suffix_reg}
    Run Keyword If    ${log_enabled}    Log To Console    start add item negotiation
    #Клик доб позицию
    sleep    3
    Full Click    ${locator_add_item_button}${lot_number}
    Wait Until Element Is Enabled    ${locator_item_description}${id_suffix}
    Run Keyword If    ${log_enabled}    Log To Console    Click add item
    #Название предмета закупки
    ${add_classif}=    Get From Dictionary    ${item}    description
    Press Key    ${locator_item_description}${id_suffix}    ${add_classif}
    Run Keyword If    ${log_enabled}    Log To Console    Название предмета закупки ${add_classif}
    #Количество товара
    ${editItemQuant}=    Get From Dictionary    ${item}    quantity
    Wait Until Element Is Enabled    ${locator_Quantity}${id_suffix}
    Input Text    ${locator_Quantity}${id_suffix}    ${editItemQuant}
    Run Keyword If    ${log_enabled}    Log To Console    Количество товара ${editItemQuant}
    #Выбор ед измерения
    Wait Until Element Is Enabled    //*[@id="procurementSubjectUnitWrap00"]//select
    ${code}=    Get From Dictionary    ${item.unit}    code
    Select From List By Value    //*[@id="procurementSubjectUnitWrap00"]//select    ${code}
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
    Set Suite Variable    ${dkkp_id}    000
    Run Keyword If    '${is_dkpp[0]}'=='PASS'    Get OtherDK    ${item}
    Set DKKP
    Run Keyword If    ${log_enabled}    Log To Console    Выбор др ДК ${is_dkpp}
    #Срок поставки (начальная дата)
    ${delivery_Date_start}=    Get From Dictionary    ${item.deliveryDate}    startDate
    ${date_time}=    get_aladdin_formated_date    ${delivery_Date_start}
    Fill Date    ${locator_date_delivery_start}${id_suffix}    ${date_time}
    Run Keyword If    ${log_enabled}    Log To Console    Срок поставки (начальная дата) ${date_time}
    #Срок поставки (конечная дата)
    ${delivery_Date}=    Get From Dictionary    ${item.deliveryDate}    endDate
    ${date_time}=    get_aladdin_formated_date    ${delivery_Date}
    Fill Date    ${locator_date_delivery_end}${id_suffix}    ${date_time}
    Run Keyword If    ${log_enabled}    Log To Console    Срок поставки (конечная дата) ${date_time}
    #Выбор страны
    ${country}=    Get From Dictionary    ${item.deliveryAddress}    countryName
    Select From List By Label    //*[@id="procurementSubjectCountryWrap00"]//select    ${country}
    Run Keyword If    ${log_enabled}    Log To Console    Выбор страны ${country}
    #Выбор региона
    sleep    5
    ${region}=    Get From Dictionary    ${item.deliveryAddress}    region
    Set Region    ${region}    ${id_suffix_reg}     00
    Run Keyword If    ${log_enabled}    Log To Console    Выбор региона ${region}
    #Индекс
    ${post_code}=    Get From Dictionary    ${item.deliveryAddress}    postalCode
    Press Key    ${locator_postal_code}${id_suffix}    ${post_code}
    Run Keyword If    ${log_enabled}    Log To Console    Индекс ${post_code}
    ${locality}=    Get From Dictionary    ${item.deliveryAddress}    locality
    Press Key    ${locator_locality}${id_suffix}    ${locality}
    Run Keyword If    ${log_enabled}    Log To Console    Насел пункт ${locality}
    ${street}=    Get From Dictionary    ${item.deliveryAddress}    streetAddress
    Press Key    ${locator_street}${id_suffix}    ${street}
    Run Keyword If    ${log_enabled}    Log To Console    Адрес ${street}
    ${deliveryLocation_latitude}=    Get From Dictionary    ${item.deliveryLocation}    latitude
    ${deliveryLocation_latitude}    Convert Float To String    ${deliveryLocation_latitude}
    ${deliveryLocation_latitude}    String.Replace String    ${deliveryLocation_latitude}    decimal    string
    Press Key    ${locator_deliveryLocation_latitude}${id_suffix}    ${deliveryLocation_latitude}
    Run Keyword If    ${log_enabled}    Log To Console    Широта ${deliveryLocation_latitude}
    ${deliveryLocation_longitude}=    Get From Dictionary    ${item.deliveryLocation}    longitude
    ${deliveryLocation_longitude}=    Convert Float To String    ${deliveryLocation_longitude}
    ${deliveryLocation_longitude}=    String.Replace String    ${deliveryLocation_longitude}    decimal    string
    Press Key    ${locator_deliveryLocation_longitude}${id_suffix}    ${deliveryLocation_longitude}
    Run Keyword If    ${log_enabled}    Log To Console    Долгота ${deliveryLocation_longitude}
    Execute Javascript    window.scroll(1000, 1000)
    #Клик кнопку "Створити"
    Full Click    ${locator_button_create_item}${id_suffix}
    sleep    2
    Run Keyword If    ${log_enabled}    Log To Console    end add item negotiation

Publish tender
    Run Keyword And Ignore Error    Wait Until Element Is Visible    id=save_changes    5
    Run Keyword And Ignore Error    Click Button    id=save_changes
    ${id}=    Get Location
    Full Click    id=publishPurchase
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
    [Arguments]    ${lot_number}    ${lot}
    Full Click    ${locator_multilot_new}
    Wait Until Page Contains Element    ${locator_multilot_title}${lot_number}    30
    Wait Until Element Is Enabled    ${locator_multilot_title}${lot_number}
    Run Keyword And Ignore Error    Input Text    ${locator_multilot_title}${lot_number}    ${lot.title}
    Run Keyword If    '${MODE}'=='openeu'    Input Text    id=lotTitle_En_${lot_number}    ${lot.title_en}
    Input Text    id=lotDescription_${lot_number}    ${lot.description}
    Run Keyword And Ignore Error    Execute Javascript    angular.element(document.getElementById('divLotControllerEdit')).scope().lotPurchasePlan.guid='${lot.id}'
    ${budget}=    Get From Dictionary    ${lot.value}    amount
    ${text}=    Convert Float To String    ${budget}
    ${text}=    String.Replace String    ${text}    .    ,
    Input Text    id=lotBudget_${lot_number}    ${text}
    ${step}=    Get From Dictionary    ${lot.minimalStep}    amount
    ${text}=    Convert Float To String    ${step}
    ${text}=    String.Replace String    ${text}    .    ,
    Press Key    id=lotMinStep_${lot_number}    ${text}
    Press Key    id=lotMinStep_${lot_number}    00
    #Input Text    id=lotGuarantee_${d}
    Full Click    xpath=.//*[@id='updateOrCreateLot_1']//button[@class="btn btn-success"]
    Log To Console    finish lot ${lot_number}

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
    ${date_time_ten_end}=    get_aladdin_formated_date    ${tender.data.tenderPeriod.endDate}
    Fill Date    ${locator_bidDate_end}    ${date_time_ten_end}
    Full Click    id=createOrUpdatePurchase
    Full Click    ${locator_next_step}
    Log To Console    finish openEng info
    #Добавление лота
    Full Click    ${locator_multilot_new}
    ${lot}=    Get From Dictionary    ${tender.data}    lots
    ${lot}=    Get From List    ${lot}    0
    Log To Console    ${locator_multilot_title}1
    Wait Until Page Contains Element    ${locator_multilot_title}1
    Wait Until Element Is Enabled    ${locator_multilot_title}1
    Input Text    ${locator_multilot_title}1    ${lot.title}
    Input Text    ${locator_lotTitleEng}1    ${lot.title_en}
    Input Text    id=lotDescription_1    ${lot.description}
    ${budget}=    Get From Dictionary    ${lot.value}    amount
    ${text}=    Convert Float To String    ${budget}
    ${text}=    String.Replace String    ${text}    .    ,
    Press Key    id=lotBudget_1    ${text}
    ${minStep}=    Get From Dictionary    ${lot.minimalStep}    amount
    ${text_ms}=    Convert Float To String    ${lot.minimalStep.amount}
    ${text_ms}=    String.Replace String    ${text_ms}    .    ,
    Press Key    id=lotMinStep_1    ${text_ms}
    #Input Text    id=lotGuarantee_${w}
    Full Click    xpath=.//*[@id='divLotControllerEdit']/div/div/div/div[9]/div/button[1]
    Run Keyword And Ignore Error    Wait Until Page Contains Element    ${locator_toast_container}
    Run Keyword And Ignore Error    Click Button    ${locator_toast_close}
    Wait Until Page Contains Element    xpath=.//*[@id='updateOrCreateLot_1']//a[@ng-click="editLot(lotPurchasePlan)"]
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
    [Arguments]    ${feature}    ${lot_n}    ${f_id}
    aniwait
    sleep    3
    Full Click    id=add_features${lot_n}
    Wait Until Element Is Enabled    id=featureTitle_${lot_n}_${f_id}
    #Param0
    Input Text    id=featureTitle_${lot_n}_${f_id}    ${feature.title}
    Run Keyword If    '${MODE}'=='openeu'    Input Text    id=featureTitle_En_${lot_n}_${f_id}    ${feature.title_en}
    Input Text    id=featureDescription_${lot_n}_${f_id}    ${feature.description}
    # Position nec
    ${status}=    Run Keyword And Ignore Error    Dictionary Should Contain Key    ${feature}    item_id
    Run Keyword If    '${feature.featureOf}'=='item'    Run Keyword If    '${status[0]}'=='FAIL'    Select Item Param    ${feature.relatedItem}
    Run Keyword If    '${feature.featureOf}'=='item'    Run Keyword If    '${status[0]}'=='PASS'    Select Item Param Label    ${feature.item_id}
    #Enum_0_1
    Set Suite Variable    ${feature_suffix}    ${0}
    ${enums}=    Get From Dictionary    ${feature}    enum
    : FOR    ${enum}    IN    @{enums}
    \    ${val}=    Evaluate    int(${enum.value}*${100})
    \    Run Keyword If    ${val}>0    Add Enum    ${enum}    ${lot_n}_${f_id}
    \    Run Keyword If    ${val}==0    Input Text    id=featureEnumTitle_${lot_n}_${f_id}_0    ${enum.title}
    \    Run Keyword If    (${val}==0)&('${MODE}'=='openeu')    Input Text    id=featureEnumTitleEn_${lot_n}_${f_id}_0    flowers
    Wait Until Element Is Enabled    id=updateFeature_${lot_n}_${f_id}
    Full Click    id=updateFeature_${lot_n}_${f_id}

Set DKKP
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
    ${enid_}=    Evaluate    ${feature_suffix}+${1}
    Set Suite Variable    ${feature_suffix}    ${enid_}
    ${end}=    Set Variable    ${p}_${feature_suffix}
    Wait Until Page Contains Element    id=featureEnumValue_${end}    15
    Input Text    id=featureEnumValue_${end}    ${val}
    Input Text    id=featureEnumTitle_${end}    ${enum.title}
    Run Keyword And Return If    '${MODE}'=='openeu'    Input Text    id=featureEnumTitleEn_${end}    flowers

Get OtherDK
    [Arguments]    ${item}
    ${dkpp}=    Get From List    ${item.additionalClassifications}    0
    ${dkpp_id_local}=    Get From Dictionary    ${dkpp}    id
    Set Suite Variable    ${dkkp_id}    ${dkpp_id_local}

Publish tender/negotiation
    Run Keyword If    ${log_enabled}    Log To Console    start publish tender
    aniwait
    Wait Until Page Contains Element    id=publishNegotiationAutoTest    90
    Wait Until Element Is Enabled    id=publishNegotiationAutoTest
    sleep    3
    Execute Javascript    $("#publishNegotiationAutoTest").click()
    ${url}=    Get Location
    sleep    5
    Wait Until Element Is Visible    id=purchaseProzorroId    90
    ${tender_UID}=    Get Text    id=purchaseProzorroId
    ${tender_GUID}=    Get Text    id=purchaseGuid
    Log To Console    UID=${tender_UID}
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
    [Arguments]    ${region}    ${item_no}    ${id_suffix}
    Execute Javascript    var autotestmodel=angular.element(document.getElementById('select_regions${item_no}')).scope(); autotestmodel.regions.push({id:0,name:'${region}'}); autotestmodel.$apply(); autotestmodel; \ $("#select_regions${item_no} option[value='0']").attr("selected", "selected"); var autotestmodel=angular.element(document.getElementById('procurementSubject_description${id_suffix}')).scope(); autotestmodel.procurementSubject.region={}; \ autotestmodel.procurementSubject.region.id=0; autotestmodel.procurementSubject.region.name='${region}';

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
    Run Keyword And Ignore Error    Wait For Condition    return $(".page-loader").css("display")=="none"    60

Full Click
    [Arguments]    ${lc}
    Wait Until Page Contains Element    ${lc}    40
    Run Keyword And Ignore Error    Wait Until Element Is Enabled    ${lc}    15
    Run Keyword And Ignore Error    Wait Until Element Is Visible    ${lc}    15
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
    Wait Until Element Is Enabled    id=lotAmount${end}
    ${amount}=    Convert Float To String    ${params[0].data.lotValues[0].value.amount}
    Press Key    id=lotAmount${end}    ${amount}
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
    [Arguments]    ${aladdin_param_code}    ${prozorro_param_codes}
    : FOR    ${prozorro_param_cod}    IN    @{prozorro_param_codes}
    \    Return From Keyword If    '${prozorro_param_cod['code']}'=='${aladdin_param_code}'    ${prozorro_param_cod['value']}

Get Info Award
    [Arguments]    ${arguments[0]}    ${arguments[1]}
    #***Award***
    Run Keyword If    '${role}'=='viewer'    Full Click    info-purchase-tab
    Run Keyword And Ignore Error    Run Keyword If    '${role}'=='viewer'    Full Click    participants-tab
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].status'    Get Field Text    id=winner_status
    #***Award Budget***
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].value.amount'    Get Field Amount    id=procuringParticipantsAmount_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].value.currency'    Get Field Text    id=procuringParticipantsCurrency_0_0
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].value.valueAddedTaxIncluded'    View.Conv to Boolean    xpath=.//*[@ng-if='procuringParticipant.isVAT']
    #***Award Suppliers(identifier/contactPoint/address)***
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
    Run Keyword If    '${arguments[1]}'=='awards[0].complaintPeriod.endDate'    Reload Page
    Run Keyword And Ignore Error    Run Keyword If    '${arguments[1]}'=='awards[0].complaintPeriod.endDate'    Full Click    //md-next-button
    Run Keyword If    '${role}'=='viewer'    Full Click    id=results-tab
    Run Keyword If    '${MODE}'!='negotiation'    Run Keyword And Ignore Error    Full Click    //md-next-button
    Run Keyword If    '${MODE}'!='negotiation'    Full Click    id=results-tab
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].complaintPeriod.endDate'    Get Field Date    xpath=.//*[contains(@id,'ContractComplaintPeriodEnd_')]
    #***Documents***
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].documents[0].title'    Get Field Doc for paticipant    xpath=.//*[@class="ng-binding"][contains(@id,'awardsdoc')]

Get Info Contract
    [Arguments]    ${ua_id}    ${contract_status}    ${id_status}
    Run Keyword If    '${role}'=='viewer'    Full Click    id=results-tab
    ${status}=    Get Text    ${id_status}
    Load Tender    ${apiUrl}/publish/SearchTenderById?guid=ac8dd2f8-1039-4e27-8d98-3ef50a728ebf&tenderId=${ua_id}
    Reload Page
    Run Keyword If    '${role}'=='viewer'    Full Click    id=results-tab
    Return From Keyword If    '${status}'=='Очікування рішення'    pending
    Return From Keyword If    '${status}'=='Активний'    active

Get Info Contract (owner)
    [Arguments]    @{arguments}
    sleep    30
    Run Keyword If    '${role}'=='tender_owner'    Full Click    id=processing-tab
    Run Keyword And Return If    '${arguments[1]}'=='contracts[0].status'    Get Field Text    xpath=.//*[contains(@id,'ContractComplaintPeriodEnd_')]
    Run Keyword And Return If    '${arguments[1]}'=='contracts[0].status'    Execute Javascript    return $('#contractStatusName_').text();

Get ComplaintPeriod
    Run Keyword And Ignore Error    Full Click    xpath=.//*[@aria-label="Next Page"]
    Run Keyword If    '${role}'=='tender_owner'    Full Click    id=results-tab
    Run Keyword And Ignore Error    Full Click    publishContract_0
    Run Keyword And Ignore Error    Sleep    10
    Run Keyword And Ignore Error    Execute Javascript    $('#publishPurchase').click();

doc1qualification
    [Arguments]    @{arguments}
    Run Keyword And Ignore Error    Full Click    //md-next-button
    Full Click    xpath=.//*[@aria-label="Next Page"]
    Run Keyword And Ignore Error    Full Click    //md-next-button
    Click Element    id=prequalification-tab
    sleep    10
    Execute Javascript    $('#toggleQualification0').click();
    Sleep    5
    Choose File    xpath=.//input[contains(@id,'uploadFile')]    ${arguments[0]}
    Select From List By Index    xpath=.//*[contains(@id,'fileCategory')]    1
    Full Click    xpath=.//*[contains(@id,'submitUpload')]

doc2qualification
    [Arguments]    @{arguments}
    Sleep    20
    Execute Javascript    $('#toggleQualification1').click();
    Sleep    5
    Choose File    xpath=.//input[contains(@id,'uploadFile')]    ${arguments[0]}
    Sleep    5
    Select From List By Index    xpath=.//*[contains(@id,'fileCategory')]    1
    Full Click    xpath=.//*[contains(@id,'submitUpload')]

Approve qualification1
    Execute Javascript    $('#toggleQualification0').click();
    sleep    40
    Execute Javascript    $('#btn_submit0').click();
    Execute Javascript    $('#isQualified0').click();
    Execute Javascript    $('#isEligible0').click();
    Execute Javascript    $('#btn_submit_confirming0').click();

Approve qualification2
    Sleep    5
    Execute Javascript    $('#toggleQualification1').click();
    sleep    40
    Execute Javascript    $('#btn_submit1').click();
    Execute Javascript    $('#isQualified1').click();
    Execute Javascript    $('#isEligible1').click();
    Execute Javascript    $('#btn_submit_confirming1').click();
