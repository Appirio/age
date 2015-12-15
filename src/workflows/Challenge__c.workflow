<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Activate_Challenge</fullName>
        <description>Mark Challenge as Active.</description>
        <field>Active__c</field>
        <literalValue>1</literalValue>
        <name>Activate Challenge</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Date_Deactivated_to_Now</fullName>
        <description>Set Date Deactivated to Now</description>
        <field>Date_Deactivated__c</field>
        <formula>Today()</formula>
        <name>Set Date Deactivated to Now</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
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
        <fullName>Activate Challenge when Start Date arrives</fullName>
        <active>true</active>
        <description>Activate Challenge when Start Date arrives.</description>
        <formula>NOT(ISNULL(Start_Date__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Activate_Challenge</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Challenge__c.Start_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Deactivate Challenge when End date has passed</fullName>
        <active>true</active>
        <description>Deactivate Challenge when End date has passed</description>
        <formula>NOT(ISNULL(End_Date__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_Active_Flag</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Challenge__c.End_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Set Date Deactivated</fullName>
        <actions>
            <name>Set_Date_Deactivated_to_Now</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Challenge__c.Active__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the Date Deactivated field when status becomes inactive</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
