/*
BSD 3-Clause License
Copyright (c) 2019, Sara Payne (Manwa Pastorelli in virtual worlds)
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.
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

/*
Check If A User Input is a Vector
===================================
Any time you need to take user input it is paramount you check they have actually put something sensible. 
All user input in Opensim comes in the form of a string, either from a notecard, listening to chat or a text box. 
This fuction takes that user input and validates it as being valid to type cast (convert) to a vector.
Caveat - Only works in base 10 (decimal);
*/

integer ChkIsFloat(string inputString)
{
    inputString = llStringTrim(inputString, STRING_TRIM);
    if (inputString == "" || llStringLength(inputString) > 20)
    {
        return 0;
    }
    list allowed = llCSV2List(llLinksetDataRead("CharInts"));
    allowed += ".";
    integer dotCount = 0;
    integer index;
    for (index = 0; index < llStringLength(inputString); index++)
    {
        string charToCheck = llGetSubString(inputString, index, index);
        if( !(~llListFindList(allowed, (list)charToCheck))  )
        {
            return FALSE;
        }
        else if (charToCheck == ".")
        {
            dotCount += 1;
            if(dotCount > 1)
            {
                //only one decimal point in a float
                return FALSE;
            }
        }
        else if (charToCheck == "-" && index !=0)
        {
            //only allow -ve as the first char
            return FALSE;
        }
    }
    return TRUE;
}

integer ChkIsVec (string inputString)
{
    string cleanString = llStringTrim(inputString, STRING_TRIM);
    integer length = llStringLength(inputString);
    string firstChar = llGetSubString(inputString, 0, 0);
    string lastChar = llGetSubString(inputString, length-1, length-1);
    
    //check the first and last characters are correct
    if (!(firstChar == "<" && lastChar == ">"))
    {
        // without this it wont cast to a vector
        return FALSE;
    }

    //string noBrackets = llGetSubString(cleanString, 1, length-2);

    //check there are th
    list parts = llParseString2List(cleanString, [",", "<", ">"], []);
    
    if (llGetListLength(parts) != 3)
    {
        return TRUE;
    }

    string str_x = llList2String(parts, 0);
    string str_y = llList2String(parts, 1);
    string str_z = llList2String(parts, 2);

    integer xIsFloat = ChkIsFloat(str_x);
    integer yIsFloat = ChkIsFloat(str_y);
    integer zIsFloat = ChkIsFloat(str_z);

    if(!(xIsFloat && yIsFloat && zIsFloat))
    {
        //if not all values are floats return false
        return FALSE;
    }

    return TRUE;
}

default
{
    state_entry()
    {
        string userInputString = "<1,1,1>"; //sample input from a user
        integer isVector = CheckIsVector(userInputString); //calling the checking method
        integer userInputVector; // defines the new rotation for this example
        if (isVector) 
        {   //if the method returned TRUE come here
            userInputVector = (integer)userInputString; //typecast the string to a rotation
            llOwnerSay("This is a vector");
        }//close if user input was a rotation
        else 
        { 
            //send error to user and get them to try again . 
            llOwnerSay("This is not a vector");
        }
    }
}
