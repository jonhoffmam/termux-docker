#!/data/data/com.termux/files/usr/bin/expect -f

set timeout -1

spawn pkg update -y

expect {
    "default=N" {
        send -- "\r"
        exp_continue
    }
    eof {
        exit 0
    }
}
