<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Email_to_Awarded_Challenge_User</fullName>
        <description>Send Email to Awarded Challenge User</description>
        <protected>false</protected>
        <recipients>
            <field>User__c</field>
            <type>userLookup</type>
        </recipients>
        
        <senderType>CurrentUser</senderType>
        <template>Gamification/Challenge_Awarded</template>
    </alerts>
    <fieldUpdates>
        <fullName>Populate_Amount_based_on_Challenge_Rewar</fullName>
        <description>Populate Amount based on Challenge Rewar</description>
        <field>Amount__c</field>
        <formula>Challenge__r.Reward_Points__c</formula>
        <name>Populate Amount based on Challenge Rewar</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Populate Amount based on Challenge Reward Points</fullName>
        <actions>
            <name>Populate_Amount_based_on_Challenge_Rewar</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Points__c.Amount__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>If the &quot;Amount&quot; field is left blank, populate it from the &quot;Reward Points&quot; field on the related Challenge.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Send Email Notification Upon Awarding a Challenge</fullName>
        <actions>
            <name>Send_Email_to_Awarded_Challenge_User</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>Send Email Notification Upon Awarding a Challenge</description>
        <formula>RecordType.Name = &apos;Earned Points&apos;</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
