@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.testapp

import android.Manifest
import android.content.Intent
import android.os.Build
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresApi
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.ActivityCompat
import com.example.testapp.ui.theme.TestAppTheme
import kotlin.random.Random

class MainActivity : ComponentActivity() {

    var groupchats = 1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION
            ),
            0
        )
        var groupchats = listOf<GroupChat>(
                    GroupChat("Honorary Girls"),
                    GroupChat("Gym Bros"),
                    GroupChat("Little Cousins"),
                    GroupChat("Cricket"),
                    GroupChat("Druskin")
                )
        setContent {
            TestAppTheme {
                Column(
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Button(
                        onClick = {
                            Intent(applicationContext, LocationService::class.java).apply{
                                action = LocationService.ACTION_START
                                startService(this)
                            }
                        }){
                        Text(text = "Start")
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = {
                            Intent(applicationContext, LocationService::class.java).apply{
                                action = LocationService.ACTION_STOP
                                startService(this)
                            }
                            println("stop works")
                        }){
                        Text(text = "Stop")
                    }
                }
                //DisplayGroupChats(groupchats)
            }
        }
    }

    fun setGroupChatsList(newGCS: Int){
        groupchats = newGCS
    }
}


@Composable
fun DisplayGroupChats(gcs : List<GroupChat>)
{
    var groupchats by remember {
        mutableStateOf(
            gcs
        )
    }

    var isPressedAddGroupChat by remember { mutableStateOf(false)}

    if (isPressedAddGroupChat) {AddGroupChat()}

    Row (
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.End,
        modifier = Modifier
            .fillMaxHeight()
            .padding(vertical = 30.dp)
    ){
        LazyRow (
            modifier = Modifier
                .width(310.dp)
        ){
            items(groupchats){
                Spacer(Modifier.width(20.dp))
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .background(
                            shape = CircleShape,
                            color = it.color
                        )
                        //.aspectRatio(1f)
                        //.fillMaxHeight()
                        .size(100.dp)

                ){
                    Text(
                        text = it.name,
                        textAlign = TextAlign.Center,
                        fontSize = 25.sp,
                        color = Color.White,
                        modifier = Modifier
                            .padding(5.dp)
                    )
                }
            }
        }
        Box(
            contentAlignment = Alignment.CenterEnd,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
        ){
            IconButton(
                onClick = {isPressedAddGroupChat = true},
                modifier = Modifier
                    .size(100.dp)
                    .background(
                        color = Color.LightGray,
                        shape = CircleShape
                    )
            ) {
                Icon(
                    tint = Color.White,
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier
                        .size(40.dp)
                )
            }
        }
    }
}


@Composable
fun AddGroupChat() {
    var field by remember { mutableStateOf("") }
    var isPressedAdd by remember { mutableStateOf(false) }
    var isPressedBack by remember{ mutableStateOf(false) }
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = Modifier
            .fillMaxHeight()
            .fillMaxWidth()
    ){
        TextField(
            value = field,
            onValueChange = {newText -> field = newText},
            label = {
                Text(
                    text = "Groupchat Name",
                    color = Color.White
                )
            }
        )
        Row(){
            Button(
                onClick = {isPressedBack = true}
            ){
                Text(text = "Add Groupchat")
            }
            Button(
                onClick = {isPressedBack = true}
            ){
                Text(text = "Back")
            }

        }
    }
}