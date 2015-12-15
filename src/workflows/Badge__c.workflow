<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Activate_Badge</fullName>
        <description>Mark Badge as Active.</description>
        <field>Active__c</field>
        <literalValue>1</literalValue>
        <name>Activate Badge</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Active_Flag</fullName>
        <description>Update the active flag to false when end date has passed</description>
        <field>Active__c</field>
        <literalValue>0</literalValue>
        <name>Update Active Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Activate Badge when Start Date arrives</fullName>
        <active>true</active>
        <description>Activate Badge when Start Date arrives</description>
        <formula>NOT(ISNULL(Start_Date__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Activate_Badge</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Badge__c.Start_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Deactivate Badge when End date has passed</fullName>
        <active>true</active>
        <description>Deactivate Badge when End date has passed</description>
        <formula>NOT(ISNULL(End_Date__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_Active_Flag</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Badge__c.End_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
