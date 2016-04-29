# ChromeFixer

ChromeFixer is a mac app that gets you out of a tight place with Google Chrome. If you have a tab open that you cannot close, or a popup open that has a single option that you don't want to click, or you just found yourself on the wrong side of the internet. Launch ChromeFixer, choose the tabs you want to keep, and all others will be removed.

# Platform Requirements

Works on my machine (OS X 10.11.4 MacBook Pro)

# How it Works

This app works by reading the `~/Library/Application Support/Google/Chrome/Default/Current Tabs` file or the `~/Library/Application Support/Google/Chrome/Default/Current Session` file and extracting open tab data.

A special thank you to [JRBANCEL](https://github.com/JRBANCEL) and the [Chromagnon](https://github.com/JRBANCEL/Chromagnon) project for doing most of the work. I just had to port the python work to Swift.

# What if it doesn't work for me?

Follow these steps

1. Fork this repo
2. Clone your fork
3. Fix it
4. Submit a pull request

# License

Check out the [LICENSE](https://github.com/jault3/ChromeFixer/blob/master/LICENSE) file. It's a good one.
