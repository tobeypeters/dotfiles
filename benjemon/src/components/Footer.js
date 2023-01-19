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
import { NavLink, Outlet, useRoutes } from 'react-router-dom';

import { Copyright, Hyperlinks, Informational,
         Privacy, Terms } from '.';

import styles from '../App.module.css';

export function Footer() {
    const routes = useRoutes([
        { path: "/copyright", element: <Copyright /> },
        { path: "/hyperlinks", element: <Hyperlinks /> },
        { path: "/informational", element: <Informational /> },
        { path: "/privacy", element: <Privacy /> },
        { path: "/terms", element: <Terms /> },
    ])
    return (
        <>
            {routes}
            <Outlet />

            <div className={styles.footer}>
                The use of this site is governed by our <NavLink to='/hyperlinks'>Hyperlink Disclaimer</NavLink>, <NavLink to='/informational'>Informational Content Disclaimer</NavLink>, <NavLink to='/privacy'>Privacy Policy</NavLink>, and <NavLink to='/terms'>Terms of Service</NavLink>. By using this site, you acknowledge that you have read these disclaimers and policies and that you accept and will be bound by their terms. <br />
                <br />
                <NavLink to='/copyright'>Copyright</NavLink> &copy; 2023. <a href='https://en.wikipedia.org/wiki/All_rights_reserved' target='_blank' rel='noreferrer'>All rights reserved</a> &reg;
                <div className={styles.horzAlign}>
                    <NavLink className={styles.backtop} to="#" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>↑ Back to top</NavLink>
                </div>
            </div>
        </>
    )
}