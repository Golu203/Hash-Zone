# AI Project Prompt: Premium Interactive PWA Catalog & Digital Store

Use this prompt in the future to instruct an AI coding assistant (like Antigravity or Gemini) to build a copy of this platform tailored to any new business or catalog niche.

---

```markdown
You are a senior-pro software engineer. Build a premium, high-performance, web-optimized Progressive Web App (PWA) that acts as a digital catalog and direct inquiry store. The app must be fully responsive (seamlessly styled for mobile, tablet, and desktop views) and follow modern, minimalist design aesthetics with custom animations, hover-states, and premium typography.

### 1. Project Overview & Business Details
*   **Business Niche**: [INSERT BUSINESS TYPE/NICHE, e.g., Wholesale Clothing Manufacturer, Premium Electronics Distributor, Luxury Furniture Boutique]
*   **Target Audience**: [INSERT TARGET AUDIENCE, e.g., B2B retail buyers, wholesale distributors, individual retail customers]
*   **Brand Colors**: [INSERT HEX CODES OR BRAND PALETTE, e.g., Black (#000000) and Gold (#D4AF37)]
*   **Primary Action**: Customers browse the catalog and click to inquire/order directly via WhatsApp.

---

### 2. Tech Stack Requirements
*   **Frontend**: Flutter Web (PWA configuration enabled). Set up clean routing using `go_router` with SEO-friendly, bookmarkable paths (e.g. `/product/:slug`).
*   **Database & Core Backend**: Firebase Firestore.
*   **Media Hosting & Optimization**: Cloudinary (integrated with fallback to Firebase Storage if Cloudinary is unconfigured).
*   **Serverless/Signature Backend**: Vercel Serverless Functions (Node.js API) to sign secure operations.

---

### 3. Key Technical Integrations & Features

#### A. Interactive B2B/B2C WhatsApp Inquiry Integration
*   Implement a direct WhatsApp redirection button on both the product cards and the product details page.
*   The button must open a pre-filled, cleanly formatted WhatsApp chat template containing:
    *   The business's target WhatsApp number.
    *   The product title, SKU code, selected options (like Size/Color), and a direct clickable URL linking back to the product details page.
*   No styling decoration (like underlines) should be present on contact numbers in the app; they should be clean, professional, and clickable.

#### B. Automatic Cloudinary Image Deletion (Secure Serverless Architecture)
*   **Endpoint**: Build a Vercel serverless function (`/api/delete-image.js`) in Node.js.
*   **Security**: The endpoint must receive a `public_id` and sign the request server-side using environment variables (`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`), sending a secure SHA-1 signed request to Cloudinary's Destroy API. This prevents exposing private credentials in the Flutter client code.
*   **Automation**: 
    *   When a product is deleted by the admin, all associated images must be deleted from Cloudinary.
    *   When a product is edited and images are removed or replaced, only the removed images must be deleted from Cloudinary.
    *   Implement the same behavior for Hero Banners.

#### C. Two-Step Image Cropper Modal
*   When uploading catalog images or banners, the admin must go through a seamless two-step modal:
    *   **Step 1: Free Crop**: The admin crops the image freely (custom resize handles on all 8 corners/edges) to focus on the desired sub-region.
    *   **Step 2: Aspect Ratio Alignment**: The cropped bytes from Step 1 are passed into a second view to zoom, pan, and rotate the image to fit a fixed aspect ratio matching the target placement:
        *   Product Cover Card: `3:4` portrait
        *   Taxonomy Thumbnails: `1:1` square
        *   Hero Banners: `21:9` ultra-wide
*   The cropping engine must draw directly on a native-resolution canvas (`ui.PictureRecorder`) to prevent any loss of image quality.

#### D. Multi-Level Dynamic Taxonomies
*   Create a taxonomy manager supporting: **Departments/Segments** ➔ **Categories** ➔ **Subcategories**.
*   **Size Toggle**: Each Department/Segment must have a boolean toggle: `isSizeApplicable`.
    *   If `isSizeApplicable` is ON, size selection chips (e.g. XS, S, M, L, XL, or waist sizes 28–46, and large sizes 48–66) are enabled in the product editor.
    *   If `isSizeApplicable` is OFF (e.g. for fabrics or accessories), the size selection chips are automatically disabled and greyed out.

#### E. Progressive Web App (PWA) Optimization
*   Configure the web manifest (`web/manifest.json`) and loader script (`web/index.html`):
    *   Set theme color, status bars, and standalone taskbars to a custom black color (`#000000`).
    *   Provide a premium, high-contrast, padded logo with a white background for the PWA splash loading screen.
    *   Rebrand all loading subtitles, metadata descriptions, and share sheets to "Digital Store" or the custom business name.

---

### 4. Admin Dashboard Features
*   **Key Performance Indicators (KPIs)**: Display total counts for products, departments, categories, and active hero banners.
*   **Product Manager**: Complete CRUD operations, drag-and-drop image re-ordering, active state toggles (Featured / Special Offers), and custom sizes selector.
*   **Taxonomy Manager**: Configure departments, edit Category/Subcategory relationships, and toggle size applicability.
*   **Banner Manager**: Upload and align high-resolution ultra-wide (`21:9`) carousel banners with dynamic overlay texts and destination redirect paths.
*   **Settings Panel**: Manage contact numbers, address, map URLs, email addresses, and Cloudinary settings stored directly in Firestore.

---

### 5. Setup & Environment Variables
Provide placeholders and instruct me on how to fill:
*   **Firebase Config**: [INSERT FIREBASE SDK CONFIG JSON/DART]
*   **Cloudinary Credentials**:
    *   `CLOUDINARY_CLOUD_NAME`: [INSERT CLOUD NAME]
    *   `CLOUDINARY_API_KEY`: [INSERT API KEY]
    *   `CLOUDINARY_API_SECRET`: [INSERT API SECRET]
*   **WhatsApp Contact**: [INSERT TARGET WHATSAPP PHONE NUMBER]
```
