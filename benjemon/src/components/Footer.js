/*
    The MIT License(MIT)
    Copyright(c), Tobey Peters, https://github.com/tobeypeters
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software
    and associated documentation files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*  Footer.js
    Description:
        Footer component - privacy, terms, copyright, etc ...
*/
import { Link, Outlet, Route, Routes } from 'react-router-dom';

import { Copyright, Hyperlinks, Informational,
         Privacy, Rights, Terms } from './Legal';

//Test components
import Home from './Home';
import Delete from './Delete';
//Test components

import styles from '../App.module.css';

export default function Footer() {
    return (
        <>
        <Copyright />
        <Hyperlinks />
        <Informational />
        <Privacy />
        <Rights />
        <Terms />
            <Routes>
                {/* Test routes */}
                {/* <Route exact path='/' component={Home} /> */}
                <Route path="/delete" component={Delete} />
                {/* Test routes */}

                <Route path="/copyright" component={Copyright} />
                <Route path="/yyperlinks" component={Hyperlinks} />
                <Route path="/informational" component={Informational} />
                <Route path="/privacy" component={Privacy} />
                <Route path="/rights" component={Rights} />
                <Route path="/terms" component={Terms} />
            </Routes>

            <a href="https://www.example.com" target="_blank" rel="noopener noreferrer">
      This works like it should
    </a>
            <Link to='http://www.reddit.com' target="_blank" rel="noopener noreferrer">this doesn't work either</Link>

            <Link to='/delete'>Delete</Link>
            <div className={styles.footer}>
                The use of this site is governed by our <Link to='/Hyperlinks'>Hyperlink Disclaimer</Link>, <Link to='/informational'>Informational Content Disclaimer</Link>, <Link to='/privacy'>Privacy Policy</Link>, and <Link to='/terms'>Terms of Service</Link>. By using this site, you acknowledge that you have read these disclaimers and policies and that you accept and will be bound by their terms. <br />
                <br />
                <Link to='/copyright'>Copyright &copy;</Link> 2023. <Link to='/rights'>All rights reserved&reg;</Link>
            </div>

        </>
    )
}