package com.example.testapp

import androidx.compose.ui.graphics.Color
import kotlin.random.Random

class GroupChat(val name: String)
{
    val colors = arrayOf(Color.LightGray, Color.Cyan, Color.Green, Color.Magenta);
    val color = colors[Random.nextInt(colors.size)]
}