*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           Collections
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs
Library           RPA.FileSystem
Suite Teardown    Close All Browsers



# +
*** Variables ***

${URL}      https://robotsparebinindustries.com/#/robot-order
#${DOWNLOAD_URL}      https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY_AMOUNT}    5x
${GLOBAL_RETRY_INTERVAL}    1s
${OUTPUT_Folder}       ${CURDIR}${/}output
# -

*** Keywords ***
Open the robot order website
    ${URLS}=    Get Secret    Links
    Open Available Browser    ${URLS}[OrderCreatePage]
    Maximize Browser Window


*** Keywords ***
Collect Search Query From User
    Create Form    URL form
    Add Text Input    Enter the URL to download orders from    Submit
    &{response}=    Request Response
    [Return]    ${response["Submit"]}

*** Keywords ***
Get orders
    ${DOWNLOAD_URL}=    Collect search query from user
    Download    ${DOWNLOAD_URL}    overwrite=True
    ${orders}=   Read Table From Csv  orders.csv
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Wait And Click Button    xpath://button[contains(text(),'OK')]

*** Keywords ***
Fill the form  
    [Arguments]    ${row}
    Select From List By Value    head   ${row}[Head]
    Wait And Click Button   id-body-${row}[Body]
    Input Text    xpath://input[@placeholder='Enter the part number for the legs']      ${row}[Legs]
    Input Text      address     ${row}[Address]


*** Keywords ***
Preview the robot
    Wait And Click Button       preview

*** Keywords ***
Submit the order
    Wait And Click Button       order
    Element Should Be Visible   id:receipt  order not placed

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${Ordernumber}
    Wait Until Element Is Visible    id:receipt
    ${Recipt}=    Get Element Attribute    id:receipt    outerHTML     
    Html To Pdf    ${Recipt}         ${OUTPUT_Folder}${/}receipts${/}${Ordernumber}.pdf
    [Return]         ${OUTPUT_Folder}${/}receipts${/}${Ordernumber}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${Ordernumber}
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    xpath://img[@alt='Head']
    Screenshot  id:robot-preview-image  ${OUTPUT_Folder}${/}screen${/}${Ordernumber}.png
    [Return]         ${OUTPUT_Folder}${/}screen${/}${Ordernumber}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image}     ${pdf}  
    ${files}=    Create List
    ...     ${image}
    Add Files To PDF    ${files}        ${pdf}    append=True

*** Keywords ***
Go to order another robot
    Wait And Click Button       id:order-another      

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip  ${OUTPUT_Folder}${/}receipts       receipts.zip
    Archive Folder With Zip  ${OUTPUT_Folder}${/}screen       screen.zip
    Move File       ${CURDIR}${/}receipts.zip      ${OUTPUT_Folder}${/}receipts.zip     overwrite=True
    Move File       ${CURDIR}${/}screen.zip      ${OUTPUT_Folder}${/}screen.zip     overwrite=True


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log	${row}[Order number]
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds   ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
