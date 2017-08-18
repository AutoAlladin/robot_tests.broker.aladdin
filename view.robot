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

*** Keywords ***
Get Field Amount
    [Arguments]    ${_id}
    ${path}=    Set Variable    ${id}
    Wait Until Element Is Visible    ${path}
    ${tmp_val}=    Get Text    ${path}
    ${tmp_val}=    Remove String    ${tmp_val}    ${SPACE}
    ${tmp_val}=    Replace String    ${tmp_val}    ,    .
    ${tmp_val}=    Convert To Number    ${tmp_val}
    Return From Keyword    ${tmp_val}

Get Field Text
    [Arguments]    ${_id}
    Wait Until Element Is Enabled    ${_id}    40
    ${value}=    Get Text    ${_id}
    [Return]    ${value}

Prepare View
    [Arguments]    ${username}    ${argument}
    ${is_tender_open}=    Set Variable    000
    ${is_tender_open}=    Run Keyword And Ignore Error    Page Should Contain    ${argument}
    Run Keyword If    '${is_tender_open[0]}'=='FAIL'    Go To    ${USERS.users['${username}'].homepage}
    Run Keyword If    '${is_tender_open[0]}'=='FAIL'    Search tender    ${username}    ${argument}
    Wait Until Element Is Not Visible    xpath=.//div[@class='page-loader animated fadeIn']

Get Field feature.title
    [Arguments]    ${id}
    Wait Until Element Is Enabled    id=features-tab
    Full Click    id=features-tab
    Wait Until Page Contains Element    id=Feature_1_0_Title    30
    Execute Javascript    window.scroll(0, 150)
    Get Field Text    xpath=//form[contains(@id,'updateOrCreateFeature_${id}')]

Get Field Date
    [Arguments]    ${id}
    Wait Until Page Contains Element    ${id}    40
    ${startDate}=    Get Text    ${id}
    ${startDate}    Replace String    ${startDate}    ${SPACE}    T
    ${tz}=    Get Local TZ
    ${startDate}=    Set Variable    ${startDate}.000000+0${tz}:00
    Return From Keyword    ${startDate}

Set Field tenderPeriod.endDate
    [Arguments]    ${value}
    ${date_time_ten_end}=    Replace String    ${value}    T    ${SPACE}
    ${date_time_ten_end}=    Fetch From Left    ${date_time_ten_end}    +0
    Wait Until Element Is Enabled    ${locator_bidDate_end}
    Fill Date    ${locator_bidDate_end}    ${date_time_ten_end}
    Full Click    id=createOrUpdatePurchase

Set Field Amount
    [Arguments]    ${_id}    ${value}
    Wait Until Element Is Enabled    ${_id}
    ${tmp_val}=    Convert Float To String    ${value}
    Input Text    ${_id}    ${tmp_val}
    Click Element    ${_id}

Conv to Boolean
    [Arguments]    ${id}
    ${path}=    Set Variable    ${id}
    Wait Until Element Is Visible    ${path}
    ${tmp_val}=    Get Text    ${path}
    ${tmp_val}=    Remove String    ${tmp_val}    ${SPACE}
    ${tmp_val}=    Convert To Boolean    ${tmp_val}
    Return From Keyword    ${tmp_val}

Set Field Text
    [Arguments]    ${idishka}    ${text}
    Wait Until Page Contains Element    ${idishka}
    Wait Until Element Is Visible    ${idishka}
    Wait Until Element Is Enabled    ${idishka}
    Input Text    ${idishka}    ${text}

Get Field Question
    [Arguments]    ${x}    ${field}
    sleep    5
    Full Click    id=questions-tab
    Wait Until Page Contains    ${x}    60
    ${txt}=    Get Text    ${field}
    Return From Keyword    ${txt}

Get Tru PDV
    [Arguments]    ${rrr}
    ${txt}=    Get Element Attribute    purchaseIsVAT@isvat
    Return From Keyword If    '${txt}'=='true'    ${True}
    Return From Keyword If    '${txt}'!='true'    ${False}

Get Tender Status
    ${status}=    Execute Javascript    return $('#purchaseStatus').text()
    Run Keyword If    '${status}'=='1'    Return From Keyword    draft
    Run Keyword If    '${status}'=='2'    Return From Keyword    active.enquiries
    Run Keyword If    '${status}'=='3'    Return From Keyword    active.tendering
    Run Keyword If    '${status}'=='4'    Return From Keyword    active.auction
    Run Keyword If    '${status}'=='10'    Return From Keyword    active.pre-qualification

Get Contract Status
    ${contr_status}=    Execute Javascript    return $('#contractStatusName_').text()
    Run Keyword If    '${status}'=='1'    Return From Keyword    pending
    Run Keyword If    '${status}'=='2'    Return From Keyword    active

Get Field question.answer
    [Arguments]    ${x}
    Full Click    id=questions-tab
    Wait Until Page Contains    ${x}    60
    ${txt}=    Get Text    xpath=//div[contains(text(),'${x}')]
    Return From Keyword    ${txt}

Get Field Amount for latitude
    [Arguments]    ${id}
    ${path}=    Set Variable    ${id}
    Wait Until Element Is Visible    ${path}
    ${r}=    Get Text    ${path}
    ${r}=    Remove String    ${r}    ${SPACE}
    ${r}=    Convert Float To String    ${r}
    Return From Keyword    ${r}

Get Field Doc
    [Arguments]    ${idd}
    Wait Until Page Contains Element    documents-tab
    Full Click    documents-tab
    sleep    5
    ${doc_name}=    Get Text    ${idd}
    Return From Keyword    ${doc_name}

Get Field Doc for paticipant
    [Arguments]    ${idd}
    Wait Until Page Contains Element    info-purchase-tab
    Full Click    info-purchase-tab
    Full Click    participants-tab
    sleep    15
    ${name_doc_part}=    Get Text    ${idd}
    Return From Keyword    ${name_doc_part}

Get Claim Status
    [Arguments]    ${_id}
    ${text}=    Get Text    ${_id}
    Return From Keyword If    '${text}'=='Вимога'    claim
    Return From Keyword If    '${text}'=='Дано відповідь'    answered
    Return From Keyword If    '${text}'=='Вирішено'    resolved
    Return From Keyword If    '${text}'=='Скасований'    cancelled
    Return From Keyword If    '${text}'=='Чернетка'    draft
    Return From Keyword If    '${text}'=='Відхилено'    declined
    Return From Keyword If    '${text}'=='Недійсно'    invalid

Get Answer Status
    [Arguments]    ${_id}
    ${txt}=    Set Variable    ${EMPTY}
    Return From Keyword If    '${txt}'=='Недійсно'    declined
    Return From Keyword If    '${txt}'=='Відхилено'    cancelled
    Return From Keyword If    '${txt}'=='Задоволено'    resolved

Get NAward Field
    [Arguments]    ${fu}    ${is_amount}
    Full Click    participants-tab
    Return From Keyword if    ${is_amount}==${True}    Get Field Text    ${fu}
    Return From Keyword if    ${is_amount}==${False}    Get Field Amount    ${fu}

Get Satisfied
    [Arguments]    ${g}
    ${msg}=    Set Variable    0
    ${msg}=    Run Keyword And Ignore Error    Element Should Be Visible    complaintSatifiedTrue_${g}
    Return From Keyword If    '${msg[0]}'=='PASS'    ${True}
    ${msg}=    Run Keyword And Ignore Error    Element Should Be Visible    complaintSatifiedFalse_${g}
    Return From Keyword If    '${msg[0]}'=='PASS'    ${False}

Open Claim Form
    [Arguments]    ${uaid}
    Full Click    claim-tab
    Wait Until Page Contains Element    //span[contains(.,'${uaid}')]
    sleep    3
    ${guid}=    Get Text    //span[text()='${uaid}']/..//span[contains(@id,'complaintGuid')]
    Full Click    openComplaintForm_${guid}
    Wait Until Element Is Enabled    complaintStatus_${guid}
    [Return]    ${guid}

Get Bid Status
    [Arguments]    ${aladdin_bid_status}
    ${txt}=    Get Text    ${aladdin_bid_status}
    Return From Keyword If    'Подана'=='${txt}'    invalid

Get qualification status
    [Arguments]    ${_id}
    Full Click    prequalification-tab
    ${status}=    Get Text    ${_id}
    Return From Keyword If    '${status}'=='Очікування рішення'    pending
