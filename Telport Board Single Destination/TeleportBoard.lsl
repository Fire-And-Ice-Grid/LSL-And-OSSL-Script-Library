/*
BSD 3-Clause License
Copyright (c) 2020, Sara Payne
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/ 

vector landing;
vector lookAt;
string gridUri = "";
string regionName = "";
string destination = ""; 
integer debug = FALSE;
integer mainMenuChannel;
integer mainMenuChannelListen;
key imageUUID;
string name;

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    mainMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
    mainMenuChannelListen = llListen(mainMenuChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (mainMenuChannelListen, FALSE); //turns off listeners for main menu channel
}//close set up listeners

string locationTestString(string input)
{
    string testValue = "TpLocation_";
    string testString = llGetSubString(input, 0, llStringLength(testValue)-1);
    string locationName = "";
    if (testString == testValue)
    {
        list elements = llParseStringKeepNulls(input, "_", "!");
        locationName = llList2String(elements, 1);
    }
    return locationName;
}

string CleanUpString(string inputString)
{ 
    string cleanString = llStringTrim( llToLower(inputString), STRING_TRIM );
    return cleanString;   
}

ProcessInstructionLine(string instruction, string data)
{
    if (debug)
    {
        llOwnerSay("Debug:ProcessInstruction: Instruction:" + instruction + " Data:" + data);
    }
    if (instruction == "landing")
    {
        landing = (vector)data;
    }
    else if (instruction == "lookat")
    {
        lookAt = (vector)data;
    }
    else if (instruction == "griduri")
    {
        gridUri = data;
    }
    else if (instruction == "region")
    {
        regionName = data;
    }
    else if (instruction =="image")
    {
        imageUUID = data;
    }
    else if (instruction == "name")
    {
        name = data;
    }
}

ReadConfigCards(string notecardName)
{   //Reads the named config card if it exists
    if (llGetInventoryType(notecardName) == INVENTORY_NOTECARD)
    {   //only come here if the name notecard actually exists, otherwise give the user an error
        integer notecardLength = osGetNumberOfNotecardLines(notecardName); //gets the length of the notecard
        integer index; //defines the index for the next line
        for (index = 0; index < notecardLength; ++index)
        {    //loops through the notecard line by line  
            string currentLine = osGetNotecardLine(notecardName,index); //contents of the current line exactly as it is in the notecard
            string firstChar = llGetSubString(currentLine, 0,0); //gets the first character of this line
            integer equalsIndex = llSubStringIndex(currentLine, "="); //gets the position of hte equals sign on this line if it exists
            if (currentLine != "" && firstChar != "#" && equalsIndex != -1 )
            {   //only come here if the line has content, it does not start with # and it contains an equal sign
                string instruction = llGetSubString (currentLine, 0, equalsIndex-1); //everything before the equals sign
                string data = llGetSubString(currentLine, equalsIndex+1, -1); //everything after the equals sign    
                instruction = CleanUpString (instruction); //sends the instruvtion to the cleanup method to remove white space and turn to lower case
                data = CleanUpString (data); //sends the data to the cleanup method to remove white space and turn to lower case
                ProcessInstructionLine(instruction, data); //sends the instruction and the data to the Process instruction method
            }//close if the line is valid
            else
            {
                if ( (currentLine != "") && (firstChar != "#") && (equalsIndex == -1))
                {
                    llOwnerSay("Line number: " + (string)index + " is malformed. It is not blank, and does not begin with a #, yet it contains no equals sign.");

                }
            }
        }
    }//close if the notecard exists
    else 
    {   //the named notecard does not exist, send an error to the user. 
        llOwnerSay ("The notecard called " + notecardName + " is missing, please address this");
    }//close error the notecard does not exist
}//close read config card. 

Teleport(key aviUUID)
{
    if (gridUri == "")
    {
        destination = regionName;
    }
    else
    {
        destination = gridUri + "/" + regionName;
    }
        
    if (destination == "" || destination == "/")
    {
         if (debug)
         {
             llOwnerSay("Debug:Teleport: No Desination, same region tp");
         }
        osTeleportAgent(aviUUID, landing, lookAt);
    }
    else
    {
        if (debug)
        {
            llOwnerSay("Debug:Teleport: Desitination Set as: " + destination);
        }
        osTeleportAgent(aviUUID, destination, landing, lookAt);
    }    
    llRegionSayTo(aviUUID, 0,  "Teleporting you to" + name);
}

string SetLocationName()
{
    if (debug) llOwnerSay("Debug:SetLocationName:Entered");
    string locationName = "";
    if (name == "")
    {
        if (debug) llOwnerSay("Debug:SetLocationName:Empty Name string found");
        if (regionName == "")
        {
            if (debug) llOwnerSay("Debug:SetLocationName:Empty Region Name found, location name set to the region name");
            locationName += llGetRegionName();
        }
        else
        {
            if (debug) llOwnerSay("Debug:SetLocationName:location name set to the region name");
            locationName += regionName;
        }
        if (gridUri == "")
        {
            locationName += "@" + osGetGridName();
        }
        else
        {
            locationName += gridUri;
        }
    }
    else
    {
        locationName = name;
    }
    if (debug) llOwnerSay("Debug:SetLocationName:LocationName: " + locationName);
    return locationName;
}

DeliverInfo(key aviUUID)
{
   list inventoryItems =[];
   integer inventoryNumber = llGetInventoryNumber(INVENTORY_ALL); 
   integer index;
   for (index = 0; index < inventoryNumber; ++index )
   {
        string itemName = llGetInventoryName(INVENTORY_ALL, index);
        if (debug)
        {
            llOwnerSay("Debug:DeliverInfo:ItemName: " + itemName);
        }
        
        if (!(itemName == llGetScriptName() || itemName == "TpLocation"))
        {
            if (debug)
            {
                llOwnerSay("Debug:DevliverInfo:" + itemName + "added to deliverables");
            }
            if (llGetInventoryPermMask(itemName, MASK_OWNER) & PERM_COPY)
            {
                inventoryItems += itemName;
            }
            else
            {
                llSay(0, "Unable to copy the item named '" + itemName + "'.");
            }
        }
    }
    if (inventoryItems == [] )
    {
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "No copiable items found, sorry.");
    }
    else llGiveInventoryList(aviUUID, llGetObjectName(), inventoryItems);    // 3.0 seconds delay
    llResetScript();
}

UpdateImage()
{
    llSetLinkPrimitiveParamsFast(ALL_SIDES, [PRIM_TEXTURE, ALL_SIDES, imageUUID, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
}

ProcessMenuChoices(key aviUUID, string message)
{
    if (message == "Teleport")
    {
        Teleport(aviUUID);
    }
    else if (message == "GetInfo")
    {
        DeliverInfo(aviUUID);
    }
}

default
{
  on_rez(integer start_param)
  {
    llResetScript();
  }

  changed(integer change) // something changed, take action
  {
      if(change & (CHANGED_OWNER | CHANGED_REGION_RESTART | CHANGED_INVENTORY)) 
      {
          llResetScript();
      }
  } 
  
  state_entry()
  {
    SetUpListeners();
    ReadConfigCards("TpLocation");
    UpdateImage();
    llSetObjectName(SetLocationName() + " Teleport Board");
  }
  
  touch_start(integer num_detected) 
  {
    llListenControl (mainMenuChannelListen, TRUE);
    list buttons = ["Teleport", "GetInfo"];
    llDialog(llDetectedKey(0), "Please select from the following options", buttons, mainMenuChannel); 
    llSetTimerEvent(30);    
  }
  
  listen(integer channel, string name, key uuid, string message)
  {//listens on the set channels, then depending on the heard channel sends the message for processing. 
      if (channel == mainMenuChannel)
      {
          ProcessMenuChoices(uuid, message);  
      }
  }//close listen 
    
  timer()
  {
      llWhisper(PUBLIC_CHANNEL, "sorry the menu timed out, please click again");
      llResetScript();
  }
}