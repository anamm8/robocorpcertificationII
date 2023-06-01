*** Settings ***
Documentation       Template robot main suite.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download orders file
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    6x    1s    Preview the robot
        Wait Until Keyword Succeeds    6x    1s    Submit the order
        ${pdf}=    Store the order receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take screenshot of the robot image    ${row}[Order number]
        Embed robot screenshot to PDF    ${screenshot}    ${pdf}
        Order other robot
    END
    Create ZIP with PDF files
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    ${table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${table}

    FOR    ${row}    IN    @{table}
        Log    ${row}
    END

Close the annoying modal
    Wait Until Element Is Visible    //*[@id="root"]/div/div[1]/div
    Click Button    css:button.btn.btn-danger

Fill the form
    [Arguments]    ${row}
    Log    ${row}
    Wait Until Element Is Visible    xpath://*[@id="head"]
    Select From List By Index    xpath://*[@id="head"]    ${row}[Head]
    Click Button    xpath://*[@id="id-body-${${row}[Body]}"]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    xpath://*[@id="address"]    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    order
    Wait Until Element Is Visible    id:order-completion

Store the order receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${order_completion_html}=    Get Element Attribute    id:order-completion    outerHTML
    ${order_completion_path}=    Set Variable    ${OUTPUT_DIR}${/}files${/}receipt_${order_number}.pdf
    Html To Pdf    ${order_completion_html}    ${order_completion_path}
    RETURN    ${order_completion_path}

Take screenshot of the robot image
    [Arguments]    ${order_number}
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}files${/}screenshot_${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot_path}
    RETURN    ${screenshot_path}

Embed robot screenshot to PDF
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}

    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf

Order other robot
    Click Button    order-another

Create ZIP with PDF files
    ${zip_name}=    Set Variable    ${OUTPUT_DIR}${/}PdfComScreenshots.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}files    ${zip_name}

Close the browser
    Close Browser
