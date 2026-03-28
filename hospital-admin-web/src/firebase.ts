import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBtpsSwr4pCahsENPaEKflLaCdQqlh_pco",
  appId: "1:1007762784529:web:3c6eab2ba67443c6f2ccb0",
  messagingSenderId: "1007762784529",
  projectId: "hospital-app-aditya",
  authDomain: "hospital-app-aditya.firebaseapp.com",
  storageBucket: "hospital-app-aditya.firebasestorage.app"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
