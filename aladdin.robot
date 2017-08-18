*** Settings ***
Library           String
Library           Collections
Library           Selenium2Library
Resource          ../../op_robot_tests/tests_files/keywords.robot
Resource          ../../op_robot_tests/tests_files/resource.robot
Resource          Locators.robot
Library           DateTime
Library           conv_timeDate.py
Resource          aladdin_keywords.robot
Resource          view.robot

*** Variables ***
${js}             ${EMPTY}
${log_enabled}    ${EMPTY}
${start_date}     ${EMPTY}
${page_load_count}    ${0}
${apiUrl}         ${EMPTY}

*** Keywords ***
Підготувати клієнт для користувача
    [Arguments]    ${username}
    [Documentation]    Відкриває переглядач на потрібній сторінці, готує api wrapper тощо
    Set Suite Variable    ${apiUrl}    http://192.168.95.153:92
    ${user}=    Get From Dictionary    ${USERS.users}    ${username}
    Comment    Open Browser    ${user.homepage}    ${user.browser}    desired_capabilities=nativeEvents:false
    ${chrome options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    ${prefs}    Create Dictionary    prompt_for_download=false    download.default_directory=${OUTPUT_DIR}    download.directory_update=True
    Call Method    ${chrome options}    add_experimental_option    prefs    ${prefs}
    Create Webdriver    Chrome    chrome_options=${chrome options}
    Goto    ${user.homepage}
    Set Window Position    @{user.position}
    Set Window Size    @{user.size}
    Run Keyword If    '${role}'!='viewer'    Login    ${user}

Підготувати дані для оголошення тендера
    [Arguments]    ${username}    @{arguments}
    [Documentation]    Змінює деякі поля в tender_data (автоматично згенерованих даних для оголошення тендера) згідно з особливостями майданчика
    Set Suite Variable    ${log_enabled}    ${False}
    #замена названия компании
    ${tender_data}=    Set Variable    ${arguments[0]}
    Set To Dictionary    ${tender_data.data.procuringEntity}    name=Тестовая компания
    Set To Dictionary    ${tender_data.data.procuringEntity.identifier}    legalName=Тестовая компания    id=11111111
    Set To Dictionary    ${tender_data.data.procuringEntity.address}    region=Київська    countryName=Україна    locality=м. Київ    streetAddress=ул. 2я тестовая    postalCode=12312
    Set To Dictionary    ${tender_data.data.procuringEntity.contactPoint}    name=Тестовый Закупщик    telephone=+380504597894    url=http://192.168.80.169:90/Profile#/company
    ${items}=    Get From Dictionary    ${tender_data.data}    items
    ${item}=    Get From List    ${items}    0
    : FOR    ${en}    IN    @{items}
    \    ${is_dkpp}=    Run Keyword And Ignore Error    Dictionary Should Contain Key    ${en}    additionalClassifications
    \    Run Keyword If    ('${is_dkpp[0]}'=='PASS')    Log To Console    ${en.additionalClassifications[0].id}
    \    Run Keyword If    ('${is_dkpp[0]}'=='PASS')    Set To Dictionary    ${en.additionalClassifications[0]}    id=7242    description=Монтажники електронного устаткування
    \    ...    scheme=ДК003
    Set List Value    ${items}    0    ${item}
    Set To Dictionary    ${tender_data.data}    items    ${items}
    Return From Keyword    ${tender_data}
    [Return]    ${tender_data}

Створити тендер
    [Arguments]    ${role}    ${tender_data}
    [Documentation]    Створює однопредметний тендер
    Run Keyword And Return If    '${MODE}'=='belowThreshold'    Допороговый однопредметный тендер    ${tender_data}
    Run Keyword And Return If    '${MODE}'=='openeu'    Открытые торги с публикацией на англ    ${tender_data}
    Run Keyword And Return If    '${MODE}'=='openua'    Открытые торги с публикацией на укр    ${tender_data}
    Run Keyword And Return If    '${MODE}'=='negotiation'    Переговорная мультилотовая процедура    ${tender_data}
    [Return]    ${UAID}

Внести зміни в тендер
    [Arguments]    ${username}    ${tender_uaid}    ${field_name}    ${field_value}
    [Documentation]    Змінює значення поля field_name на field_value в тендері tender_uaid
    Close All Browsers
    Aladdin.Підготувати клієнт для користувача    ${username}
    Search tender    ${username}    ${tender_uaid}
    Full Click    id=purchaseEdit
    Wait Until Page Contains Element    id=save_changes
    Run Keyword If    '${field_name}'=='tenderPeriod.endDate'    Set Field tenderPeriod.endDate    ${field_value}
    Run Keyword If    '${field_name}'=='description'    Set Field Text    id=description    ${field_value}
    Full Click    id=save_changes
    Full Click    id=movePurchaseView
    Run Keyword If    '${MODE}'=='negotiation'    Publish tender/negotiation
    Run Keyword If    '${MODE}'!='negotiation'    Publish tender

Завантажити документ
    [Arguments]    ${username}    ${filepath}    ${tender_uaid}
    [Documentation]    Завантажує супроводжуючий тендерний документ в тендер tender_uaid. Тут аргумент filepath – це шлях до файлу на диску
    ${idd}=    Get Location
    ${idd}=    Fetch From Left    ${idd}    \#/info-purchase
    ${id}=    Fetch From Right    ${idd}    /
    Go To    ${USERS.users['${username}'].homepage}/Purchase/Edit/${id}#/info-purchase
    Load document    ${filepath}    Tender    ${EMPTY}
    Full Click    ${locator_finish_edit}
    Run Keyword If    '${MODE}'=='negotiation'    Publish tender/negotiation
    Run Keyword If    '${MODE}'!='negotiation'    Publish tender

Пошук тендера по ідентифікатору
    [Arguments]    ${username}    ${tender_uaid}
    [Documentation]    Знаходить тендер по його UAID, відкриває його сторінку
    Go To    ${USERS.users['${username}'].homepage}
    Search tender    ${username}    ${tender_uaid}
    ${guid}=    Get Text    id=purchaseGuid
    Comment    ${api}=    Fetch From Left    ${USERS.users['${username}'].homepage}    90
    Load Tender    ${apiUrl}/api/sync/purchases/${guid}

Оновити сторінку з тендером
    [Arguments]    ${username}    ${tender_uaid}
    [Documentation]    Оновлює інформацію на сторінці, якщо відкрита сторінка з тендером, інакше переходить на сторінку з тендером tender_uaid
    ${next_page_load_count}    Evaluate    ${page_load_count}+${1}
    Set Suite Variable    ${page_load_count}    ${next_page_load_count}
    ${is_load_before_crash}=    Evaluate    ${page_load_count}>4
    Run Keyword If    ${is_load_before_crash}    Close All Browsers
    Run Keyword If    ${is_load_before_crash}    Aladdin.Підготувати клієнт для користувача    ${username}
    Run Keyword If    ${is_load_before_crash}    Search tender    ${username}    ${tender_uaid}
    Run Keyword If    ${is_load_before_crash}    Set Suite Variable    ${page_load_count}    ${1}
    Load Tender    ${apiUrl}/api/sync/purchase/tenderID/tenderID=${tender_uaid}
    Switch Browser    1
    Reload Page

Отримати інформацію із тендера
    [Arguments]    ${username}    @{arguments}
    [Documentation]    Return значення поля field_name, яке бачить користувач username
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    #***Purchase***
    Run Keyword And Return If    '${arguments[1]}'=='tenderID'    Get Field Text    id=purchaseProzorroId
    Run Keyword And Return If    '${arguments[1]}'=='status'    Get Tender Status
    #***Purchase Title ***
    Run Keyword And Return If    '${arguments[1]}'=='title'    Get Field Text    id=purchaseTitle
    Run Keyword And Return If    '${arguments[1]}'=='title_en'    Get Field Text    id=purchaseTitle_En
    Run Keyword And Return If    '${arguments[1]}'=='title_ru'    Get Field Text    id=purchaseTitle_Ru
    #***Purchase Description ***
    Run Keyword And Return If    '${arguments[1]}'=='description'    Get Field Text    xpath=.//*[@id='purchse-controller']/div/div[1]/div[1]/div/p[1]
    Run Keyword And Return If    '${arguments[1]}'=='description'    Get Field Text    id=purchaseDescription
    Run Keyword And Return If    '${arguments[1]}'=='description_en'    Get Field Text    id=purchaseDescription_En
    #***Purchse Cause***
    Run Keyword And Return If    '${arguments[1]}'=='causeDescription'    Get Field Text    id=CauseDescription
    Run Keyword And Return If    '${arguments[1]}'=='cause'    Execute Javascript    return $('#Cause').text()
    #***Purchase Periods ***
    Run Keyword And Return If    '${arguments[1]}'=='enquiryPeriod.startDate'    Get Field Date    id=purchasePeriodEnquiryStart
    Run Keyword And Return If    '${arguments[1]}'=='enquiryPeriod.endDate'    Get Field Date    id=purchasePeriodEnquiryEnd
    Run Keyword And Return If    '${arguments[1]}'=='tenderPeriod.startDate'    Get Field Date    id=purchasePeriodTenderStart
    Run Keyword And Return If    '${arguments[1]}'=='tenderPeriod.endDate'    Get Field Date    id=purchasePeriodTenderEnd
    #***Purchase Budget ***
    Run Keyword And Return If    '${arguments[1]}'=='value.amount'    Get Field Amount    xpath=.//*[@id='purchaseBudget']
    Run Keyword And Return If    '${arguments[1]}'=='value.currency'    Get Field Text    ${locator_purchaseCurrency_viewer}
    Run Keyword And Return If    '${arguments[1]}'=='value.valueAddedTaxIncluded'    View.Conv to Boolean    xpath=.//*[@ng-if='purchase.purchase.isVAT']
    Run Keyword And Return If    '${arguments[1]}'=='minimalStep.amount'    Get Field Amount    id=minStepValue
    #***Purchase ProcuringEntity(identifier/contactPoint/address)***
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.name'    Get Field Text    id=identifierName
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.name'    Get Field Text    id=purchaseProcuringEntityCompanyName
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.identifier.id'    Get Field Text    id=identifierCode
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.identifier.scheme'    Get Field Text    id=identifierScheme
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.identifier.legalName'    Get Field Text    id=identifierName
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.contactPoint.name'    Get Field Text    id=purchaseProcuringEntityContactPointName
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.contactPoint.telephone'    Get Field Text    id=purchaseProcuringEntityContactPointPhone
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.contactPoint.url'    Get Field Text    id=purchaseProcuringEntityContactPointUrl
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.address.postalCode'    Get Field Text    id=purchaseAddressZipCode
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.address.region'    Get Field Text    id=purchaseAddressRegion
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.address.streetAddress'    Get Field Text    id=purchaseAddressStreet
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.address.countryName'    Get Field Text    ${locator_purchaseAddressCountryName_viewer}
    Run Keyword And Return If    '${arguments[1]}'=='procuringEntity.address.locality'    Get Field Text    ${locator_purchaseAddressLocality_viewer}
    #***Purchase Items ***
    Run Keyword And Return If    '${arguments[1]}'=='items[1].classification.scheme'    Get Field Text    id=procurementSubjectCpvTitle_0_0
    Run Keyword And Return If    '${arguments[1]}'=='items[1].description'    Get Field Text    id=procurementSubjectDescription_0_0
    Run Keyword And Return If    '${arguments[1]}'=='items[1].additionalClassifications[0].description'    Get Field Text    id=procurementSubjectOtherClassTitle_0_0
    Run Keyword And Return If    '${arguments[1]}'=='items[0].deliveryLocation.latitude'    Get Field Amount for latitude    xpath=.//*[@class="col-md-8 ng-binding"][contains (@id,'procurementSubjectLatitude')]
    Run Keyword And Return If    '${arguments[1]}'=='items[0].additionalClassifications[0].id'    Get Field Text    id=procurementSubjectOtherClassCode_1_0
    #***Purchase Features ***
    Run Keyword And Return If    '${arguments[1]}'=='features[0].title'    Get Field feature.title    0_0
    Run Keyword And Return If    '${arguments[1]}'=='features[1].title'    Get Field feature.title    1_0
    Run Keyword And Return If    '${arguments[1]}'=='features[2].title'    Get Field feature.title    1_1
    Run Keyword And Return If    '${arguments[1]}'=='features[3].title'    Get Field feature.title    1_2
    #***Documents***
    Comment    Run Keyword If    '${arguments[1]}'=='documents[0].title'    Full Click    id=documents-tab
    Run Keyword And Return If    '${arguments[1]}'=='documents[0].title'    Get Field Doc    xpath=.//*[contains(@id,'docFileName')]
    #***Questions***
    Reload Page
    Run Keyword And Return If    '${arguments[1]}'=='questions[0].title'    Get Field Text    xpath=.//*[@class="col-md-9 ng-binding"][contains(@id,'questionTitle')]
    Run Keyword And Return If    '${arguments[1]}'=='questions[0].description'    Get Field Text    xpath=.//*[@class="col-md-9 ng-binding"][contains(@id,'questionDescription')]
    Run Keyword And Return If    '${arguments[1]}'=='questions[0].answer'    Get Field Text    xpath=.//*[@class="col-sm-10 ng-binding"][contains(@id,'questionAnswer')]
    #***Awards***
    ${awardInfo}=    Get Substring    ${arguments[1]}    0    9
    Run Keyword And Return If    '${awardInfo}'=='awards[0]'    Get Info Award    ${arguments[0]}    ${arguments[1]}
    Run Keyword And Return If    '${arguments[1]}'=='awards[0].complaintPeriod.endDate'    Get Field Date    xpath=.//*[contains(@id,'ContractComplaintPeriodEnd_')]
    #***Contracts***
    ${contractInfo}=    Get Substring    ${arguments[1]}    0    12
    Run Keyword And Return If    '${contractInfo}'=='contracts[0]'    Get Info Contract    ${arguments[0]}    ${arguments[1]}
    #***Status***
    Run Keyword And Return If    '${arguments[1]}'=='qualifications[0].status'    Get qualification status    xpath=.//*[contains(@id,'qualificationStatus_')][0]
    Run Keyword And Return If    '${arguments[1]}'=='qualifications[1].status'    Get qualification status    xpath=.//*[contains(@id,'qualificationStatus_')][1]
    [Return]    ${field_value}

Задати запитання на тендер
    [Arguments]    ${username}    ${tender_uaid}    ${question}
    [Documentation]    Задає питання question від імені користувача username в тендері tender_uaid
    Close All Browsers
    Aladdin.Підготувати клієнт для користувача    ${username}
    Search tender    ${username}    ${tender_uaid}
    Full Click    id=questions-tab
    Full Click    id=add_discussion
    Wait Until Page Contains Element    id=confirm_creationForm
    Select From List By Value    name=OfOptions    0
    Input Text    name=Title    ${question.data.title}
    Input Text    name=Description    ${question.data.description}
    Full Click    id=confirm_creationForm

Подати цінову пропозицію
    [Arguments]    ${username}    ${tender_uaid}    ${bid}    ${to_id}    ${params}
    [Documentation]    Створює нову ставку в тендері tender_uaid
    Close All Browsers
    Aladdin.Підготувати клієнт для користувача    ${username}
    Aladdin.Пошук тендера по ідентифікатору    ${username}    ${tender_uaid}
    Full Click    id=do-proposition-tab
    ${msg}=    Run Keyword And Ignore Error    Dictionary Should Contain Key    ${bid.data}    lotValues
    Run Keyword If    '${msg[0]}'=='FAIL'    Add Bid Tender    ${bid.data.value.amount}
    Run Keyword If    '${msg[0]}'!='FAIL'    Add Bid Lot    ${bid}    ${to_id}    ${params}

Змінити цінову пропозицію
    [Arguments]    ${username}    ${tender_uaid}    ${fieldname}    ${fieldvalue}
    [Documentation]    Змінює поле fieldname (сума, неціновий показник тощо) в раніше створеній ставці в тендері tender_uaid
    Aladdin.Оновити сторінку з тендером    ${username}    ${tender_uaid}
    Full Click    id=do-proposition-tab
    Run Keyword And Ignore Error    Full Click    //a[contains(@id,'openLotForm')]
    Run Keyword And Ignore Error    Full Click    id=editButton
    Run Keyword And Ignore Error    Full Click    id=editLotButton_0
    Run Keyword And Ignore Error    Full Click    confirmInvalidButton
    Run Keyword And Ignore Error    Set Field Amount    id=bidAmount    ${fieldvalue}
    Run Keyword And Ignore Error    Set Field Amount    id=lotAmount_0    ${fieldvalue}
    Run Keyword And Ignore Error    Full Click    id=submitBid
    Run Keyword And Ignore Error    Full Click    id=lotSubmit_0
    Run Keyword And Ignore Error    Full Click    id=publishButton

Створити постачальника, додати документацію і підтвердити його
    [Arguments]    ${username}    ${ua_id}    ${s}    ${filepath}
    ${url}=    Get Location
    ${url}=    Fetch From Left    ${url}    \#/info-purchase
    ${id}=    Fetch From Right    ${url}    /
    Go To    ${USERS.users['${username}'].homepage}/Purchase/Edit/${id}#/info-purchase
    Wait Until Element Is Enabled    ${locator_participant}
    Click Element    ${locator_participant}
    Wait Until Page Contains Element    ${locator_add_participant}
    Wait Until Element Is Enabled    ${locator_add_participant}
    Full Click    ${locator_add_participant}
    #Цена предложения
    ${amount}=    Get From Dictionary    ${s.data.value}    amount
    Wait Until Page Contains Element    ${locator_amount}
    Wait Until Element Is Enabled    ${locator_amount}
    Input Text    ${locator_amount}    ${amount}
    #Выбрать участника
    Click Element    xpath=.//*[@id='createOrUpdateProcuringParticipantNegotiation_0_0']/div/div[3]/div[2]/label
    Click Element    xpath=.//*[@id='awardEligible_0_0']/div[1]/div[2]/div
    #Код
    ${sup}=    Get From List    ${s.data.suppliers}    0
    ${code_edrpou}=    Get From Dictionary    ${sup.identifier}    id
    Wait Until Page Contains Element    ${locator_code_edrpou}
    Wait Until Element Is Enabled    ${locator_code_edrpou}
    Press Key    ${locator_code_edrpou}    ${sup.identifier.id}
    #Нац реестр
    ${reestr}=    Get From Dictionary    ${sup.identifier}    scheme
    Select From List By Value    ${locator_reestr}    UA-EDR
    Press Key    ${locator_reestr}    ${reestr}
    #Наименование участника (legalName)
    ${legalName}=    Get From Dictionary    ${sup.identifier}    legalName
    Press Key    ${locator_legalName}    ${legalName}
    #Выбор страны
    ${country}=    Get From Dictionary    ${sup.address}    countryName
    Select From List By Label    xpath=.//*[contains(@id,'select_countries')]    ${country}
    #Выбор региона
    ${region}=    Get From Dictionary    ${sup.address}    region
    Execute Javascript    var autotestmodel=angular.element(document.getElementById('procuringParticipantLegalName_0_0')).scope(); autotestmodel.procuringParticipant.procuringParticipants.region=autotestmodel.procuringParticipant.procuringParticipants.country; autotestmodel.procuringParticipant.procuringParticipants.region={id:0,name:'${region}',initName:'${region}'};
    Execute Javascript    window.scroll(1000, 1000)
    #Индекс
    ${post_code}=    Get From Dictionary    ${sup.address}    postalCode
    Press Key    ${locator_post_code}    ${post_code}
    #Насел пункт
    ${locality}=    Get From Dictionary    ${sup.address}    locality
    Press Key    ${locator_local}    ${locality}
    #Адрес
    ${street}=    Get From Dictionary    ${sup.address}    streetAddress
    Press Key    ${locator_street_ng}    ${street}
    #ФИО
    ${name}=    Get From Dictionary    ${sup.contactPoint}    name
    Press Key    ${locator_name}    ${name}
    #e-mail
    ${mail}=    Get From Dictionary    ${sup.contactPoint}    email
    Press Key    ${locator_mail_ng}    ${mail}
    #Телефон
    ${phone}=    Get From Dictionary    ${sup.contactPoint}    telephone
    Press Key    ${locator_phone_ng}    ${phone}
    #Click but
    Wait Until Element Is Visible    ${locator_save_participant}
    Click Button    ${locator_save_participant}
    #Add doc
    Run Keyword And Ignore Error    Wait Until Page Does Not Contain    Учасник Збережена успішно
    Wait Until Element Is Enabled    xpath=.//input[contains(@id,'uploadFile')]
    sleep    10
    Choose File    xpath=.//input[contains(@id,'uploadFile')]    ${filepath}
    Select From List By Index    xpath=.//*[@class='form-control b-l-none ng-pristine ng-untouched ng-valid ng-empty'][contains(@id,'fileCategory')]    1
    Full Click    xpath=.//*[@class='btn btn-success'][contains(@id,'submitUpload')]
    #save
    Wait Until Page Contains Element    ${locator_finish_edit}
    Full Click    ${locator_finish_edit}
    #publish
    Publish tender/negotiation

Отримати інформацію із предмету
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=procurement-subject-tab
    Wait Until Element Is Enabled    id=procurement-subject
    ${item_path}=    Set Variable    xpath=//h4[contains(@id,'procurementSubjectDescription')][contains(.,\'${arguments[1]}\')]
    Run Keyword And Return If    '${arguments[2]}'=='description'    Get Field Text    ${item_path}
    Run Keyword And Return If    '${arguments[2]}'=='deliveryDate.startDate'    Get Field Date    ${item_path}/../../..//div[contains(@id,'procurementSubjectDeliveryStart')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryDate.endDate'    Get Field Date    ${item_path}/../../..//div[contains(@id,'procurementSubjectDeliveryEnd')]
    Run Keyword And Return If    '${arguments[2]}'=='classification.scheme'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectCpvSheme')]
    Run Keyword And Return If    '${arguments[2]}'=='classification.id'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectCpvCode')]
    Run Keyword And Return If    '${arguments[2]}'=='classification.description'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectCpvTitle')]
    Run Keyword And Return If    '${arguments[2]}'=='unit.name'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectUnitName')]
    Run Keyword And Return If    '${arguments[2]}'=='unit.code'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectUnitCode')]
    Run Keyword And Return If    '${arguments[2]}'=='quantity'    Get Field Amount    ${item_path}/../../..//span[contains(@id,'procurementSubjectQuantity')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryLocation.longitude'    Get Field Amount    ${item_path}/../../..//div[contains(@id,'procurementSubjectLongitude')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryLocation.latitude'    Get Field Amount    ${item_path}/../../..//div[contains(@id,'procurementSubjectLatitude')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryAddress.countryName'    Get Field Text    ${item_path}/../../..//div[contains(@id,'procurementSubjectCounrtyName')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryAddress.postalCode'    Get Field Text    ${item_path}/../../..//div[contains(@id,'procurementSubjectZipCode')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryAddress.region'    Get Field Text    ${item_path}/../../..//div[contains(@id,'procurementSubjectRegionName')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryAddress.locality'    Get Field Text    ${item_path}/../../..//div[contains(@id,'procurementSubjectLocality')]
    Run Keyword And Return If    '${arguments[2]}'=='deliveryAddress.streetAddress'    Get Field Text    ${item_path}/../../..//div[contains(@id,'procurementSubjectStreet')]
    Run Keyword And Return If    '${arguments[2]}'=='additionalClassifications[0].scheme'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectOtherClassSheme')]
    Run Keyword And Return If    '${arguments[2]}'=='additionalClassifications[0].id'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectOtherClassCode')]
    Run Keyword And Return If    '${arguments[2]}'=='additionalClassifications[0].description'    Get Field Text    ${item_path}/../../..//span[contains(@id,'procurementSubjectOtherClassTitle')]

Отримати інформацію із лоту
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Wait Until Element Is Enabled    id=view-lots-tab
    Click Element    id=view-lots-tab
    Wait Until Element Is Enabled    id=view-lots
    sleep    5
    Run Keyword And Return If    '${arguments[2]}'=='title'    Get Field Text    xpath=//h4[@id='Lot-1-Title'][contains(.,'${arguments[1]}')]
    Run Keyword And Return If    '${arguments[2]}'=='value.amount'    Get Field Amount    id=Lot-1-Budget
    Run Keyword And Return If    '${arguments[2]}'=='description'    Get Field Text    id=Lot-1-Description
    Run Keyword And Return If    '${arguments[2]}'=='minimalStep.amount'    Get Field Amount    id=Lot-1-MinStep
    Run Keyword And Return If    '${arguments[2]}'=='value.currency'    Get Field Text    id=Lot-1-Currency
    Run Keyword And Return If    '${arguments[2]}'=='description'    Get Field Text    id=Lot-1-Description
    Run Keyword And Return If    '${arguments[2]}'=='minimalStep.valueAddedTaxIncluded'    Get Tru PDV    purchaseIsVAT@isvat
    Run Keyword And Return If    '${arguments[2]}'=='minimalStep.currency'    Get Field Text    id=Lot-1-Currency
    Run Keyword And Return If    '${arguments[2]}'=='value.valueAddedTaxIncluded'    Get Tru PDV    purchaseIsVAT@isvat
    [Return]    ${field_value}

Отримати інформацію із нецінового показника
    [Arguments]    ${username}    @{arguments}
    sleep    5
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=features-tab
    Wait Until Element Is Enabled    id=features
    ${d}=    Set Variable    ${arguments[1]}
    Wait Until Element Is Enabled    xpath=//div[contains(@id,'_Title')][contains(.,'${d}')]    30
    sleep    5
    Run Keyword And Return If    '${arguments[2]}'=='title'    Get Field Text    xpath=//div[contains(@id,'_Title')][contains(.,'${d}')]
    Run Keyword And Return If    '${arguments[2]}'=='description'    Get Field Text    xpath=//div[contains(@id,'_Title')][contains(.,'${d}')]/../../../div/div/div[contains(@id,'featureDescription')]
    Run Keyword And Return If    '${arguments[2]}'=='featureOf'    Get Element Attribute    xpath=//div[contains(@id,'_Title')][contains(.,'${d}')]/../../../../../../../..@itemid

Завантажити документ в лот
    [Arguments]    ${username}    ${file}    ${ua_id}    ${lot_id}
    Close All Browsers
    Aladdin.Підготувати клієнт для користувача    ${username}
    Search tender    ${username}    ${ua_id}
    Full Click    id=purchaseEdit
    Load document    ${file}    Lot    ${lot_id}
    Full Click    id=movePurchaseView
    Publish tender

Змінити лот
    [Arguments]    ${username}    ${ua_id}    ${lot_id}    ${field_name}    ${field_value}
    Aladdin.Оновити сторінку з тендером    ${username}    ${ua_id}
    Full Click    id=purchaseEdit
    Wait Until Page Contains Element    id=save_changes
    Full Click    id=lots-tab
    Full Click    //h4[contains(.,'${lot_id}')]/../../../..//a[contains(@id,'editLot')]
    Run Keyword If    '${field_name}'=='value.amount'    Set Field Amount    id=lotBudget_1    ${field_value}
    Full Click    xpath=.//*[@id='divLotControllerEdit']//button[@class='btn btn-success']
    Full Click    id=basicInfo-tab
    Full Click    id=save_changes
    Full Click    id=movePurchaseView
    Publish tender

Додати неціновий показник на предмет
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=purchaseEdit
    Wait Until Page Contains Element    id=save_changes
    Full Click    id=features-tab
    ${fi}=    Set Variable    ${arguments[1]}
    ${fi.item_id}=    Set Variable    ${arguments[2]}
    Add Feature    ${fi}    1    0
    Full Click    id=basicInfo-tab
    Full Click    id=movePurchaseView
    Publish tender

Видалити неціновий показник
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=purchaseEdit
    Wait Until Page Contains Element    id=save_changes
    Full Click    id=features-tab
    Full Click    xpath=//div[contains(text(),'${arguments[1]}')]/../..//a[contains(@id,'updateOrCreateFeatureDeleteButton')]
    Full Click    xpath=//div[@class='jconfirm-buttons']/button[1]
    Full Click    id=basicInfo-tab
    Full Click    id=movePurchaseView
    Publish tender

Створити вимогу про виправлення умов закупівлі
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=claim-tab
    Wait Until Element Is Enabled    id=add_claim    60
    Full Click    id=add_claim
    ${data}=    Set Variable    ${arguments[1].data}
    Wait Until Page Contains Element    save_claim    60
    Wait Until Element Is Visible    add_claim_select_type    60
    Select From List By Value    add_claim_select_type    0
    Input Text    claim_title    ${arguments[1].data.title}
    Input Text    claim_descriptions    ${arguments[1].data.description}
    Choose File    add_file_complaint    ${arguments[2]}
    Full Click    save_claim
    Wait Until Page Contains Element    //a[contains(@id,'openComplaintForm')][contains(text(),"${arguments[1].data.title}")]    60
    ${cg}=    Get Text    //a[contains(@id,'openComplaintForm')][contains(.,'${arguments[1].data.title}')]/../../..//span[contains(@id,'complaintProzorroId')]
    Comment    ${cg}=    Get Text    //div[contains(@id,'complaintTitle')][contains(text(),"${arguments[1].data.title}")]/../../../../..//span[contains(@id,'complaintProzorroId')]
    Log To Console    new tender claim ${cg}
    Return From Keyword    ${cg}

Отримати інформацію із запитання
    [Arguments]    ${username}    @{arguments}
    sleep    5
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Run Keyword And Return If    '${arguments[2]}'=='title'    Get Field Question    ${arguments[1]}    xpath=//div[@id='questionTitle_0'][contains(.,'${arguments[1]}')]
    Run Keyword And Return If    '${arguments[2]}'=='description'    Get Field Question    ${arguments[1]}    xpath=//div[contains(.,'${arguments[1]}')]/div/div[contains(@id,'questionDescription')]
    Run Keyword And Return If    '${arguments[2]}'=='answer'    Get Field Question    ${arguments[1]}    xpath=//div[contains(.,'${arguments[1]}')]//div[contains(@id,'questionAnswer')]

Підтвердити підписання контракту
    [Arguments]    ${username}    @{arguments}
    ${guid}=    Get Text    id=purchaseGuid
    ${api}=    Fetch From Left    ${USERS.users['${username}'].homepage}    :90
    Execute Javascript    $.get('${api}:92/api/sync/purchases/${guid}');
    Full Click    id=processing-tab
    #add contract
    Wait Until Element Is Enabled    xpath=.//input[contains(@id,'uploadFile')]
    sleep    5
    Choose File    xpath=.//*[contains(@id,'uploadFile')]    /home/ova/robot_tests/src/robot_tests.broker.aladdin/LICENSE.txt
    Select From List By Index    xpath=.//*[contains(@id,'fileCategory')]    2
    sleep    10
    Mouse Down    xpath=.//*[@id='processingContract0']/div/div
    Full Click    xpath=.//*[@class="btn btn-success"][contains(@id,'submitUpload')]
    Input Text    id=processingContractContractNumber    777
    ${signed}=    Get Text    xpath=.//*[@class="ng-binding"][contains(@id,'ContractComplaintPeriodEnd_')]
    Mouse Down    xpath=.//*[@id='processingContract0']/div/div
    Full Click    id=processingContractDateSigned
    Mouse Down    xpath=.//*[@id='processingContract0']/div/div
    Full Click    id=processingContractStartDate
    Mouse Down    xpath=.//*[@id='processingContract0']/div/div
    Full Click    id=processingContractEndDate
    Mouse Down    xpath=.//*[@id='processingContract0']/div/div
    sleep    15
    Element Should Be Enabled    xpath=.//*[contains(@id,'saveContract_')]
    Mouse Down    xpath=.//*[@id='processingContract0']/div/div
    Click Button    xpath=.//*[contains(@id,'saveContract_')]
    Publish tender/negotiation

Відповісти на запитання
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=questions-tab
    Wait Until Page Contains    ${arguments[2]}
    Full Click    xpath=//div[contains(text(),'${arguments[2]}')]/../../../..//button[@id='reply_answer']
    Full Click    xpath=//textarea[@ng-model='element.answer']
    Input Text    xpath=//textarea[@ng-model='element.answer']    ${arguments[1].data.answer}
    Full Click    xpath=//div[contains(text(),'${arguments[2]}')]/../../../..//button[@id='save_answer']

Отримати інформацію із документа
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    info-purchase-tab
    Full Click    id=documents-tab
    sleep    15
    Run Keyword And Return If    '${arguments[2]}'=='title'    Get Text    //div[contains(@id,'docFileName')]/span[contains(text(),'${arguments[1]}')]

Отримати документ
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=documents-tab
    ${title}=    Get Field Text    //div[contains(@id,'docFileName')]/span[contains(.,'${arguments[1]}')]
    Full Click    //div[contains(@id,'docFileName')]/span[contains(.,'${arguments[1]}')]/../../../../../..//a[contains(@id,'strikeDocFileNameBut')]
    sleep    3
    Return From Keyword    ${title}

Отримати інформацію із пропозиції
    [Arguments]    ${username}    @{arguments}
    sleep    5
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=do-proposition-tab
    sleep    5
    Run Keyword And Ignore Error    Full Click    id=openLotForm_0
    Run Keyword And Return If    '${arguments[1]}'=='value.amount'    Get Field Amount    id=bidAmount
    Run Keyword And Return If    '${arguments[1]}'=='lotValues[0].value.amount'    Get Field Amount    id=lotAmount_0
    Run Keyword And Return If    '${arguments[1]}'=='status'    Get Bid Status    id=bidStatusName_0

Завантажити документ в ставку
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[1]}
    Full Click    id=do-proposition-tab
    Run Keyword And Ignore Error    Full Click    //a[contains(@id,'openLotForm')]
    Run Keyword And Ignore Error    Full Click    id=editLotButton_0
    Run Keyword And Ignore Error    Full Click    id=editButton
    Run Keyword And Ignore Error    Full Click    id=openLotDocuments_technicalSpecifications_0
    Run Keyword And Ignore Error    Full Click    id=openDocuments_biddingDocuments
    Run Keyword And Ignore Error    Run Keyword If    '${arguments[2]}'=='financial_documents'    Full Click    id=openTenderDocuments_commercialProposal_0
    Run Keyword And Ignore Error    Run Keyword If    '${arguments[2]}'=='qualification_documents'    Full Click    openTenderDocuments_qualificationDocuments_0
    Run Keyword And Ignore Error    Run Keyword If    '${arguments[2]}'=='eligibility_documents'    Full Click    id=openTenderDocuments_eligibilityDocuments_0
    Run Keyword And Ignore Error    Choose File    id=bidDocInput_biddingDocuments    ${arguments[1]}
    Run Keyword And Ignore Error    Choose File    bidLotDocInputBtn_technicalSpecifications_0    ${arguments[1]}
    Capture Page Screenshot
    Run Keyword And Ignore Error    Full Click    id=submitBid
    Run Keyword And Ignore Error    Full Click    id=lotSubmit_0
    Run Keyword And Ignore Error    Full Click    id=publishButton

Змінити документ в ставці
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=do-proposition-tab
    Run Keyword And Ignore Error    Full Click    //a[contains(@id,'openLotForm')]
    Run Keyword And Ignore Error    Full Click    id=editLotButton_0
    Run Keyword And Ignore Error    Full Click    id=editButton
    Run Keyword And Ignore Error    Full Click    id=openLotDocuments_technicalSpecifications_0
    Run Keyword And Ignore Error    Full Click    id=openDocuments_biddingDocuments
    Run Keyword And Ignore Error    Choose File    id=bidDocInput_biddingDocuments    ${arguments[1]}
    Run Keyword And Ignore Error    Choose File    bidLotDocInputBtn_technicalSpecifications_0    ${arguments[1]}
    Capture Page Screenshot
    Run Keyword And Ignore Error    Full Click    id=submitBid
    Run Keyword And Ignore Error    Full Click    id=lotSubmit_0
    Run Keyword And Ignore Error    Full Click    id=publishButton

Отримати посилання на аукціон для учасника
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    ${rrr}=    Get Element Attribute    //a[contains(@id,'purchaseUrlOwner')]@href
    Return From Keyword    ${rrr}
    [Return]    ${rrr}

Отримати посилання на аукціон для глядача
    [Arguments]    ${username}    @{arguments}
    Close All Browsers
    Aladdin.Підготувати клієнт для користувача    ${username}
    Aladdin.Пошук тендера по ідентифікатору    ${username}    ${arguments[0]}
    Run Keyword And Return    Get Element Attribute    //a[@id='auctionUrl' or @id='purchaseUrlOwner_0']@href

Додати неціновий показник на лот
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=purchaseEdit
    Full Click    id=features-tab
    ${fi}=    Set Variable    ${arguments[1]}
    ${fi.item_id}=    Set Variable    ${arguments[2]}
    Add Feature    ${fi}    1    0
    Full Click    id=movePurchaseView
    Publish tender

Отримати документ до лоту
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=documents-tab
    ${title}=    Get Field Text    //div[contains(@id,'docFileName')]/span[contains(.,'${arguments[2]}')]
    Full Click    //div[contains(@id,'docFileName')]/span[contains(.,'${arguments[2]}')]/../../../../../..//a[contains(@id,'strikeDocFileNameBut')]
    Return From Keyword    ${title}

Відповісти на вимогу про виправлення умов закупівлі
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    ${guid}=    Open Claim Form    ${arguments[1]}
    Full Click    makeDecisionComplaint_${guid}
    Wait Until Page Contains Element    name=ResolutionTypes
    Run Keyword If    '${arguments[2].data.resolutionType}'=='resolved'    Select From List By Value    complaintResolutionType_${guid}    3
    Run Keyword If    '${arguments[2].data.resolutionType}'=='declined'    Select From List By Value    complaintResolutionType_${guid}    2
    Run Keyword If    '${arguments[2].data.resolutionType}'=='invalid'    Select From List By Value    complaintResolutionType_${guid}    1
    Input Text    complaintResolution_${guid}    ${arguments[2].data.resolution}
    Full Click    makeComplaintResolution_${guid}
    Log To Console    ${guid} \ ${arguments[2].data.resolutionType}
    Return From Keyword    '${arguments[2].data.resolutionType}'=='declined'

Задати запитання на лот
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=questions-tab
    Full Click    id=add_discussion
    Wait Until Page Contains Element    id=confirm_creationForm
    Select From List By Value    name=OfOptions    1
    ${lot_name}=    get text    xpath=//option[contains(@label,'${arguments[1]}')]
    Select From List By Label    name=LotsAddOptions    ${lot_name}
    Input Text    name=Title    ${arguments[2].data.title}
    Input Text    name=Description    ${arguments[2].data.description}
    Full Click    id=confirm_creationForm

Задати запитання на предмет
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=questions-tab
    Full Click    id=add_discussion
    Wait Until Page Contains Element    id=confirm_creationForm
    Select From List By Value    name=OfOptions    2
    ${item_name}=    get text    xpath=//option[contains(@label,'${arguments[2]}')]
    Select From List By Label    name=LotsAddOptions    ${item_name}
    Input Text    name=Title    ${arguments[2]}.data.title}
    Input Text    name=Description    ${arguments[2]}.data.description}
    Full Click    id=confirm_creationForm

Отримати інформацію із скарги
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    ${guid}=    Open Claim Form    ${arguments[1]}
    Run Keyword And Return If    '${arguments[2]}'=='status'    Get Claim Status    complaintStatus_${guid}
    Run Keyword And Return If    '${arguments[2]}'=='title'    Get Field Text    complaintTitle_${guid}
    Run Keyword And Return If    '${arguments[2]}'=='description'    Get Field Text    complaintDescription_${guid}
    Run Keyword And Return If    '${arguments[2]}'=='resolutionType'    Get Claim Status    complaintResolutionTypeName_${guid}
    Run Keyword And Return If    '${arguments[2]}'=='resolution'    Get Field Text    complaintResolution_${guid}
    Run Keyword And Return If    '${arguments[2]}'=='satisfied'    Get Satisfied    ${guid}
    Run Keyword And Return If    '${arguments[2]}'=='cancellationReason'    Get Field Text    complaintCancellationReason_${guid}

Підтвердити вирішення вимоги про виправлення умов закупівлі
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    ${guid}=    Open Claim Form    ${arguments[1]}
    Run Keyword If    ${arguments[2].data.satisfied}==${True}    Full Click    complaintYes_${guid}
    Run Keyword If    ${arguments[2].data.satisfied}==${False}    Full Click    complaintNo_${guid}
    Log To Console    ${guid} satisfied ${arguments[2].data.satisfied}

Створити вимогу про виправлення умов лоту
    [Arguments]    ${username}    @{arguments}
    Close All Browsers
    Aladdin.Підготувати клієнт для користувача    ${username}
    Aladdin.Пошук тендера по ідентифікатору    ${username}    ${arguments[0]}
    Full Click    id=claim-tab
    Wait Until Element Is Enabled    id=add_claim    60
    Full Click    id=add_claim
    ${data}=    Set Variable    ${arguments[1].data}
    Wait Until Page Contains Element    save_claim    60
    Wait Until Element Is Visible    add_claim_select_type    60
    Select From List By Value    add_claim_select_type    1
    ${label}=    Get Text    //option[contains(@label,'${arguments[2]}')]
    Select From List By Label    LotsAddOptions    ${label}
    Input Text    claim_title    ${arguments[1].data.title}
    Input Text    claim_descriptions    ${arguments[1].data.description}
    Choose File    add_file_complaint    ${arguments[3]}
    Full Click    save_claim
    Wait Until Page Contains Element    //a[contains(@id,'openComplaintForm')][contains(text(),"${arguments[1].data.title}")]    60
    ${cg}=    Get Text    //a[contains(@id,'openComplaintForm')][contains(.,'${arguments[1].data.title}')]/../../..//span[contains(@id,'complaintProzorroId')]
    Comment    ${cg}=    Get Text    //div[contains(@id,'complaintTitle')][contains(text(),"${arguments[1].data.title}")]/../../../../..//span[contains(@id,'complaintProzorroId')]
    Log To Console    new lot claim ${cg}
    Return From Keyword    ${cg}

Підтвердити вирішення вимоги про виправлення умов лоту
    [Arguments]    ${username}    @{arguments}
    Aladdin.Підтвердити вирішення вимоги про виправлення умов закупівлі    ${username}    @{arguments}

Створити чернетку вимоги про виправлення умов закупівлі
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=claim-tab
    Wait Until Element Is Enabled    id=add_claim    60
    Full Click    id=add_claim
    ${data}=    Set Variable    ${arguments[1].data}
    Wait Until Page Contains Element    save_claim    60
    Select From List By Value    add_claim_select_type    0
    Input Text    claim_title    ${arguments[1].data.title}
    Input Text    claim_descriptions    ${arguments[1].data.description}
    Execute Javascript    $('#save_claim_draft').click()
    Wait Until Page Contains Element    //a[contains(@id,'openComplaintForm')][contains(text(),"${arguments[1].data.title}")]    60
    ${cg}=    Get Text    //a[contains(@id,'openComplaintForm')][contains(.,'${arguments[1].data.title}')]/../../..//span[contains(@id,'complaintProzorroId')]
    Comment    ${cg}=    Get Text    //div[contains(@id,'complaintTitle')][contains(text(),"${arguments[1].data.title}")]/../../../../..//span[contains(@id,'complaintProzorroId')]
    Log To Console    new draft claim ${cg}
    Return From Keyword    ${cg}

Створити чернетку вимоги про виправлення умов лоту
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=claim-tab
    Wait Until Element Is Enabled    id=add_claim    60
    Full Click    id=add_claim
    ${data}=    Set Variable    ${arguments[1].data}
    Wait Until Page Contains Element    save_claim    60
    Select From List By Value    add_claim_select_type    1
    ${label}=    Get Text    //option[contains(@label,'${arguments[2]}')]
    Select From List By Label    LotsAddOptions    ${label}
    Input Text    claim_title    ${arguments[1].data.title}
    Input Text    claim_descriptions    ${arguments[1].data.description}
    Execute Javascript    $('#save_claim_draft').click()
    Wait Until Page Contains Element    //a[contains(@id,'openComplaintForm')][contains(text(),"${arguments[1].data.title}")]    60
    ${cg}=    Get Text    //a[contains(@id,'openComplaintForm')][contains(.,'${arguments[1].data.title}')]/../../..//span[contains(@id,'complaintProzorroId')]
    Comment    ${cg}=    Get Text    //div[contains(@id,'complaintTitle')][contains(text(),"${arguments[1].data.title}")]/../../../../..//span[contains(@id,'complaintProzorroId')]
    Log To Console    new draft lot claim ${cg}
    Return From Keyword    ${cg}
    [Teardown]

Скасувати вимогу про виправлення умов закупівлі
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    ${guid}=    Open Claim Form    ${arguments[1]}
    Full Click    cancelComplaint_${guid}
    Wait Until Page Contains Element    complaintCancellationReason_${guid}    60
    Input Text    complaintCancellationReason_${guid}    ${arguments[2].data.cancellationReason}
    Full Click    cancelComplaint_${guid}
    Log To Console    cansel claim ${guid}
    [Teardown]

Скасувати вимогу про виправлення умов лоту
    [Arguments]    ${username}    @{arguments}
    Aladdin.Скасувати вимогу про виправлення умов закупівлі    ${username}    @{arguments}

Відповісти на вимогу про виправлення умов лоту
    [Arguments]    ${username}    @{arguments}
    Aladdin.Відповісти на вимогу про виправлення умов закупівлі    ${username}    @{arguments}

Змінити документацію в ставці
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=do-proposition-tab
    Run Keyword And Ignore Error    Full Click    //a[contains(@id,'openLotForm')]
    Run Keyword And Ignore Error    Full Click    id=editLotButton_0
    Run Keyword And Ignore Error    Full Click    id=editButton
    Run Keyword And Ignore Error    Full Click    id=openLotDocuments_technicalSpecifications_0
    Run Keyword And Ignore Error    Full Click    id=openDocuments_biddingDocuments
    Run Keyword And Ignore Error    Choose File    id=bidDocInput_biddingDocuments    ${arguments[1]}
    Run Keyword And Ignore Error    Choose File    bidLotDocInputBtn_technicalSpecifications_0    ${arguments[1]}
    Capture Page Screenshot
    Run Keyword And Ignore Error    Full Click    id=submitBid
    Run Keyword And Ignore Error    Full Click    id=lotSubmit_0
    Run Keyword And Ignore Error    Full Click    id=publishButton

Відповісти на вимогу про виправлення визначення переможця
    [Arguments]    ${username}    @{arguments}
    Aladdin.Відповісти на вимогу про виправлення умов закупівлі    ${username}    @{arguments}

Отримати інформацію із документа до скарги
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    ${guid}=    Open Claim Form    ${arguments[1]}
    Run Keyword And Return If    '${arguments[3]}'=='title'    Get Text    //div[contains(@id,'docFileName')]/span[contains(.,'${arguments[2]}')]

Створити вимогу про виправлення визначення переможця
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=claim-tab
    Wait Until Element Is Enabled    id=add_claim    60
    Full Click    id=add_claim
    ${data}=    Set Variable    ${arguments[1].data}
    Wait Until Page Contains Element    save_claim    60
    Wait Until Element Is Visible    add_claim_select_type    60
    Select From List By Value    add_claim_select_type    3
    Select From List By Index    AwardsAddOptions    1
    Input Text    claim_title    ${arguments[1].data.title}
    Input Text    claim_descriptions    ${arguments[1].data.description}
    Choose File    add_file_complaint    ${arguments[3]}
    Full Click    save_claim
    Wait Until Page Contains Element    //a[contains(@id,'openComplaintForm')][contains(text(),"${arguments[1].data.title}")]    60
    ${complaint_guid}=    Get Text    //a[contains(@id,'openComplaintForm')][contains(.,'${arguments[1].data.title}')]/../../..//span[contains(@id,'complaintProzorroId')]
    Log To Console    new award claim ${complaint_guid}
    Return From Keyword    ${complaint_guid}

Завантажити документ рішення кваліфікаційної комісії
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[1]}
    Run Keyword And Ignore Error    Full Click    //md-next-button
    Full Click    processing-tab
    Wait Until Page Contains Element    //button[contains(@id,'awardAcceptDecision')]
    Wait Until Page Contains Element    //file-category-upload
    Choose File    //file-category-upload[contains(@id,'awardUploadFile')]//input[contains(@id,'uploadFile')]    ${arguments[0]}
    Select From List By Index    //file-category-upload[contains(@id,'awardUploadFile')]//select[contains(@id,'fileCategory')]    3
    Full Click    //file-category-upload[contains(@id,'awardUploadFile')]//a[contains(@id,'submitUpload')]

Підтвердити постачальника
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Run Keyword And Ignore Error    Full Click    //md-next-button
    Full Click    processing-tab
    Wait Until Page Contains Element    //button[contains(@id,'awardAcceptDecision')]
    Full Click    //button[contains(@id,'awardAcceptDecision')]
    Run Keyword And Ignore Error    Full Click    //div[@ng-show='showAcceptDecision']/md-checkbox
    Run Keyword And Ignore Error    Full Click    //button[@ng-show='showBtnAcceptDecision']
    Run Keyword And Ignore Error    Full Click    //button[@class="btn btn-success pull-right"]
    Wait Until Element Is Visible    //span[@id="contractProzorroId"]    60
    ${res}=    Get Text    //span[@id="contractProzorroId"]
    Return From Keyword    ${res}

Створити чернетку вимоги про виправлення визначення переможця
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    id=claim-tab
    Wait Until Element Is Enabled    id=add_claim    60
    Full Click    id=add_claim
    ${data}=    Set Variable    ${arguments[1].data}
    Wait Until Page Contains Element    save_claim    60
    Wait Until Element Is Visible    add_claim_select_type    60
    Select From List By Value    add_claim_select_type    3
    Select From List By Index    AwardsAddOptions    1
    Input Text    claim_title    ${arguments[1].data.title}
    Input Text    claim_descriptions    ${arguments[1].data.description}
    Execute Javascript    $('#save_claim_draft').click()
    Wait Until Page Contains Element    //a[contains(@id,'openComplaintForm')][contains(text(),"${arguments[1].data.title}")]    60
    ${cg}=    Get Text    //a[contains(@id,'openComplaintForm')][contains(.,'${arguments[1].data.title}')]/../../..//span[contains(@id,'complaintProzorroId')]
    Log To Console    new draft award claim ${cg}
    Return From Keyword    ${cg}

Завантажити документ у кваліфікацію
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[1]}
    Run Keyword And Ignore Error    Full Click    //md-next-button
    Click Element    id=prequalification-tab
    Comment    Wait Until Page Contains Element    //button[contains(@id,'prequalification')]
    Click Element    xpath=.//*[contains(@id,'toggleQualification')]
    Wait Until Page Contains Element    xpath=.//*[@id='prequalification']/div/div/div[1]
    Choose File    xpath=.//*[@id='prequalification']/div/div/div[1]    ${arguments[0]}
    Full Click    xpath=.//*[contains(@id,'btn_submit')]

Підтвердити кваліфікацію
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[1]}
    Click Element    prequalification-tab
    Full Click    xpath=.//*[contains(@id,'toggleQualification')][0]
    Full Click    xpath=.//*[contains(@id,'btn_submit')]
    Click Element    xpath=.//*[@id='prequalification']/div/div/div[1]
    Click Element    xpath=.//*[@id='prequalification']/div/div/div[1]
    Full Click    xpath=.//*[contains(@id,'btn_submit')]

Затвердити остаточне рішення кваліфікації
    [Arguments]    ${username}    @{arguments}
    Aladdin.Оновити сторінку з тендером    ${username}    ${arguments[0]}
    Full Click    ActiveStandStill

Підтвердити вирішення вимоги про виправлення визначення переможця
    [Arguments]    ${username}    @{arguments}
    Aladdin.Підтвердити вирішення вимоги про виправлення умов закупівлі    ${username}    @{arguments}

Скасувати вимогу про виправлення визначення переможця
    [Arguments]    ${username}    @{arguments}
    Aladdin.Скасувати вимогу про виправлення умов закупівлі    ${username}    @{arguments}
