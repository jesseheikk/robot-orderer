*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Browser.Selenium
Library           RPA.Archive
Library           RPA.PDF
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets

*** Variables ***
${RECEIPT_FOLDER}=    ${OUTPUT_DIR}/receipts
${RECEIPT_ZIP}=       ${OUTPUT_DIR}/receipts.zip
#${ORDER_URL}=         https://robotsparebinindustries.com/#/robot-order
#${CSV_URL}=           https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_url}=    Collect CSV URL from the user
    ${orders}=     Get orders    ${csv_url}
    Open robot order website
    FOR    ${order}    IN    @{orders}
        Close popup window
        Fill order form               ${order}
        ${screenshot}=                Save screenshot of the robot
        Submit order
        ${pdf}=                       Save receipt as PDF    ${order}[Order number]
        Add screenshot to PDF file    ${pdf}    ${screenshot}
        Order another robot
    END
    Archive receipts

    [Teardown]    Close All Browsers

*** Keywords ***
Collect CSV URL from the user
    Add text input    url    label=Input CSV URL
    ${response}=      Run dialog

    [Return]    ${response.url}

Archive receipts
    Archive Folder With Tar    ${receipt_folder}    ${RECEIPT_ZIP}

Add screenshot to PDF file
    [Arguments]    ${pdf}    ${screenshot}

    # Add Files To Pdf needs a list as an argument
    @{files}=       Create List     ${screenshot}

    Open Pdf            ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    ${True}
    Close Pdf

Save receipt as PDF
    [Arguments]    ${order_number}

    ${receipt_html}=      Get Element Attribute    receipt    outerHTML
    Set Local Variable    ${file_path}             ${receipt_folder}/${order_number}.pdf
    Html To Pdf           ${receipt_html}          ${file_path}

    [Return]    ${file_path}

Order another robot
    Click Button    order-another
    Wait Until Page Does Not Contain Element    order-another

Fill order form
    [Arguments]    ${order}

    Select From List By Value    head    ${order}[Head]
    Click Element                //input[@id='id-body-${order}[Body]']
                                # Using a full xpath here as the id changes randomly
    Input Text                   //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]    #this id is schetchy
    Input Text                   address    ${order}[Address]

Open robot order website
    # Getting the url from the vault
    ${secret}=    Get Secret    mysecrects
    Open Available Browser    ${secret}[order_url]

Close popup window
    Click Button    OK

Get orders
    [Arguments]    ${csv_url}

    Download      ${csv_url}             overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True

    [Return]    ${orders}

Save screenshot of the robot
    Click Button                        Preview
    Wait Until Page Contains Element    robot-preview-image
    Sleep    1s    Waiting for image to fully load
    Set Local Variable    ${file_path}              ${OUTPUT_DIR}${/}robot_preview.png
    Screenshot            id:robot-preview-image    ${file_path}

    [Return]    ${file_path}

Submit order
    Wait Until Keyword Succeeds    10 times    1s    Try to submit order

Try to submit order
    Click Button                        order
    Wait Until Page Contains Element    receipt