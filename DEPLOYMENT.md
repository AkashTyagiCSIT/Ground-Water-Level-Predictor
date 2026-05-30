# Neer Manthan - Web Deployment Guide 🚀

This guide explains how to build your Flutter Ground Water Level Predictor web application and host it for free as a public website. Having a live website link on your resume is one of the best ways to impress recruiters!

---

## 🛠️ Step 1: Build the Web App Locally

Before deploying, you must compile your Flutter codebase into web assets (HTML, CSS, JS).

1. Open your terminal in the project root directory.
2. Run the build command depending on your chosen hosting platform:

```bash
# For Vercel or Netlify (Root Base Href)
flutter build web --release

# For GitHub Pages (Scoped Base Href matching your repo name)
# Replace "Ground-Water-Level-Predictor" with your exact GitHub repository name
flutter build web --release --base-href "/Ground-Water-Level-Predictor/"
```

*This compiles the web app and stores the static assets inside the `build/web/` directory.*

---

## 🌐 Step 2: Choose a Free Hosting Platform

Here are the three easiest, 100% free hosting options for your resume:

###  Option A: GitHub Pages (Recommended)

Since your project is already on GitHub, hosting it directly via GitHub Pages is extremely convenient and matches your repository name.

#### Method 1: Using the `peanut` package (Automatic)
The `peanut` package builds your app and automatically pushes it to a dedicated `gh-pages` branch.

1. Install the `peanut` package globally:
   ```bash
   dart pub global activate peanut
   ```
2. Run peanut with your repository name as the base-href:
   ```bash
   peanut --web-renderer canvaskit --base-href="/Ground-Water-Level-Predictor/"
   ```
3. Push the newly created `gh-pages` branch to GitHub:
   ```bash
   git push origin gh-pages
   ```
4. Go to your GitHub repository -> **Settings** -> **Pages**.
5. Under **Build and deployment**, select **Deploy from a branch**, choose `gh-pages`, and select the `/ (root)` folder. Save it.
6. Your site will be live at: `https://<your-username>.github.io/Ground-Water-Level-Predictor/`

---

### ⚡ Option B: Vercel (Super Fast & Sleek)

Vercel provides ultra-fast hosting and gives you a premium-looking domain like `neer-manthan.vercel.app`.

#### Method 1: Drag & Drop (Easiest)
1. Run `flutter build web --release` on your machine.
2. Go to the [Vercel Dashboard](https://vercel.com/dashboard) and log in.
3. Simply drag and drop the `build/web/` folder directly onto the Vercel deploy canvas.
4. Your site will be built and deployed instantly!

#### Method 2: Vercel CLI
1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```
2. Open terminal in the `build/web` directory and type:
   ```bash
   vercel
   ```
3. Follow the quick prompts to link your account and deploy.

---

### ☁️ Option C: Netlify (Drag & Drop)

Netlify is another incredibly popular platform for static site hosting.

1. Run `flutter build web --release` on your machine.
2. Go to [Netlify App](https://app.netlify.com/) and sign in.
3. Scroll down to the **"Drag and drop your site folder here"** section.
4. Drag and drop the `build/web/` folder there.
5. Once uploaded, go to **Site Settings** -> **Change Site Name** to give it a custom name like `neer-manthan.netlify.app`.

---

## 💡 Pro Tips for Web Apps on your Resume

1. **Test Locally First**: You can run and test your web app locally in Chrome by running:
   ```bash
   flutter run -d chrome
   ```
2. **Add a "Live Demo" Badge**: Add this badge at the very top of your `README.md` file:
   ```markdown
   [![Live Demo](https://img.shields.io/badge/demo-online-brightgreen.svg)](https://<your-username>.github.io/Ground-Water-Level-Predictor/)
   ```
3. **No-Lag Rendering**: Flutter uses a high-performance CanvasKit renderer on web, which handles rich animations smoothly. The built-in mock/demo logic we've implemented ensures that anyone clicking your link can immediately play with the dashboard, search stations, and view predictions without needing an offline local database!
