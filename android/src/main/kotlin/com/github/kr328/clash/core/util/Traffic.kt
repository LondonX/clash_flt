package com.github.kr328.clash.core.util

import com.github.kr328.clash.core.model.Traffic

fun Traffic.trafficUpload(): Long {
    return scaleTraffic(this ushr 32)
}

fun Traffic.trafficDownload(): Long {
    return scaleTraffic(this and 0xFFFFFFFF)
}

private fun scaleTraffic(value: Long): Long {
    val type = (value ushr 30) and 0x3
    val data = value and 0x3FFFFFFF

    return when (type) {
        0L -> data
        1L -> data * 1024
        2L -> data * 1024 * 1024
        3L -> data * 1024 * 1024 * 1024
        else -> throw IllegalArgumentException("invalid value type")
    }
}