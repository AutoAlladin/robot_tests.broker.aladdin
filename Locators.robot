*** Settings ***

*** Variables ***
${item_index}     0
${locator_create_dop_zak}    xpath=.//a[@id='url_create_purchase_0']
${locator_enter}    xpath=.//*[@id='butLoginPartial']
${locator_cabinetEnter}    xpath=//*[@id='liLoginNoAuthenticated']/a
${locator_emailField}    id=Email    # id=Email
${locator_passwordField}    id=Password    # id=Password
${locator_loginButton}    id=submitLogin
${locator_buttonTenderAdd}    xpath=.//a[@href="/Purchase/Create"]    # додати допорогову закупівлю
${locator_tenderTitle}    id=title
${locator_button_create}    id=btn_create_purchase
${locator_budget}    id=budget
${locator_min_step}    id=min_step
${locator_pdv}    xpath=.//*[@id='is_vat']/div[1]/div[2]/div
${locator_discussionDate_start}    id=period_enquiry_start
${locator_discussionDate_end}    id=period_enquiry_end
${locator_bidDate_start}    id=period_tender_start
${locator_bidDate_end}    id=period_tender_end
${locator_button_next_step}    xpath=.//*[@id='next_step']
${locator_add_item_button}    id=add_procurement_subject
${locator_item_description}    id=procurementSubject_description
${locator_Quantity}    id=procurementSubject_quantity
${locator_code}    id=select_unit
${locator_button_add_cpv}    id=cls_click_
${locator_cpv_search}    id=search-classifier-text
${locator_button_add_dkpp}    //button[@itemid="otherClassifier"]
${locator_dkpp_search}    id=search-classifier-text
${locator_add_classfier}    id=add-classifier
${locator_date_delivery_end}    id=delivery_end_
${locator_button_create_item}    id=update_
${locator_check_location}    xpath=.//*[@id='is_delivary_00']/div[1]/div[2]/div
${locator_country_id}    id=select_countries
${locator_SelectRegion}    id=select_regions
${locator_postal_code}    id=zip_code_
${locator_locality}    id=locality_
${locator_street}    id=street_
${locator_search}    id=Search
${locator_search-btn}    xpath=.//*[@id='wrapper']/div/div/div/div[2]/div/div/div/div[1]/div[1]/div/div[2]/button
${locator_currency}    id=select_currencies
${locator_items}    xpath=.//*[@id='procurementSubjectTab']
${locator_deliveryLocation_latitude}    id=latutide_
${locator_deliveryLocation_longitude}    id=longitude_
${locator_check_dk}    xpath=.//*[@id='tree']
${next_step}      id=next_step
${locator_next_step}    id=next_step
${locator_input_search}    id=findbykeywords
${locator_finish_edit}    id=movePurchaseView    # завешити редагування
${locator_publish_tender}    id=publishPurchase    # публікація тендеру
${locator_toast_container}    id=toast-container
${locator_toast_close}    xpath=.//*[@class='toast-close-button']
${locator_create_negotiation}    xpath=.//*[@id='url_create_purchase_5']
${locator_description}    id=description
${locator_select_directory_causes}    xpath=.//*[@ng-bind='directoryCause.cause']
${locator_cause_description}    id=cause_description
${locator_multilot}    xpath=.//*[@id='is_multilot']/div[1]/div[2]/div
${locator_biddingUkr_create}    id=url_create_purchase_1    # id=url_create_purchase_1
${locator_UID}    id=purchaseProzorroId
${locator_click_logo}    xpath=.//*[@id='logo']/a/span/img
${locator_btn_edit_tender}    id=purchaseEdit
${locator_search_type}    id=searchType
${locator_date_delivery_start}    id=delivery_start_    # Проверить id
${locator_check_gps}    id=is_delivary_
${locator_item_description_01}    id=procurementSubject_description01
${locator_region}    id=select_regions
${locator_multilot_enabler}    xpath=.//*[@id='is_multilot']
${locator_multilot_new}    id=buttonAddNewLot
${locator_multilot_title}    id=lotTitle_
${locator_biddingEng_create}    id=url_create_purchase_2    # id=url_create_purchase_2
${locator_titleEng}    id=title_en    # id=title_en
${locator_item_descriptionEng}    id=procurementSubject_description_En    # id=procurementSubject_description_En
${locator_isMultilote}    id=is_multilot    # id=is_multilot
${locator_lotTitleEng}    id=lotTitle_En_    # id=lotTitle_En
${locator_directory_cause}    xpath=.//*[@id='select_directory_causes']/div[1]/span
${locator_participant}    xpath=html/body/div[1]/div[2]/div[2]/div/div/div/div/md-content/md-tabs/md-tabs-wrapper/md-tabs-canvas/md-pagination-wrapper/md-tab-item[3]/a
${locator_add_participant}    id=addProcuringParticipant0
${locator_amount}    id=awardAmount_0_0
${locator_check_participant}    xpath=.//*[@id='createOrUpdateProcuringParticipantNegotiation_0_0']/div/div[3]/div[1]/label
${locator_code_edrpou}    id=procuringParticipantEdrpou_0_0
${locator_reestr}    id=procuringParticipantScheme_0_0
${locator_legalName}    id=procuringParticipantLegalName_0_0
${locator_addNecPokaznyk}    id=add_features
${locator_necTitleUkr}    id=featureTitle_
${locator_post_code}    id=procuringParticipantIndex_0_0
${locator_local}    id=procuringParticipantLocality_0_0
${locator_street_ng}    id=procuringParticipantStreet_0_0
${locator_name}    id=procuringParticipantName_0_0
${locator_mail_ng}    id=procuringParticipantMail_0_0
${locator_phone_ng}    id=procuringParticipantPhone_00
${locator_save_participant}    id=updateProcuringParticipant_0_0
${locator_necPositionButton}    id=featureOf_1_
${locator_necPositionTitle}    id=featureItem_1_0
${locator_add_doc_ng}    id=addDocumentProcuringParticipantNegotiation_
${locator_cause_descr_viewer}    id=purchaseDirectoryCauseDescription
${locator_purchaseCauseDescr}    id=purchaseCauseDescription
${locator_purchaseCurrency_viewer}    id=purchaseCurrency
${locator_purchaseIsVAT_viewer}    id=purchaseIsVAT@isvat
${locator_purchaseAddressCountryName_viewer}    id=purchaseAddressCountryName
${locator_purchaseAddressLocality_viewer}    id=purchaseAddressLocality
${locator_awardEligible}    xpath=.//*[@id='awardEligible_0_0']/div[1]
